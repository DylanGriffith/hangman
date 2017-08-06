defmodule Cluster.Strategy.CloudFoundry do
  @moduledoc """
  An example configuration is below:
      config :libcluster,
        topologies: [
          cf_clustering: [
            strategy: #{__MODULE__},
            config: [
              polling_interval: 10_000]]]
  """
  use GenServer
  use Cluster.Strategy
  import Cluster.Logger

  alias Cluster.Strategy.State

  # export PATH=$PATH:/home/vcap/app/.platform_tools/erlang/bin:/home/vcap/app/.platform_tools/elixir/bin
  # iex --name a$CF_INSTANCE_INDEX@$CF_INSTANCE_INTERNAL_IP --cookie monster
  # Node.connect(

  @default_polling_interval 60_000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
  def init(opts) do
    vcap_application = Poison.decode!(System.get_env("VCAP_APPLICATION"))
    cf_api_base_uri = vcap_application["cf_api"]
    app_guid = vcap_application["application_id"]
    app_name = vcap_application["application_name"]
    config = Enum.into(Keyword.fetch!(opts, :config), %{})
    {instance_id, ""} = Integer.parse(System.get_env("CF_INSTANCE_INDEX"))

    state = %State{
      topology: Keyword.fetch!(opts, :topology),
      connect: Keyword.fetch!(opts, :connect),
      disconnect: Keyword.fetch!(opts, :disconnect),
      list_nodes: Keyword.fetch!(opts, :list_nodes),
      config: Map.merge(
        config,
        %{
          vcap_application: vcap_application,
          cf_api_base_uri: cf_api_base_uri,
          app_guid: app_guid,
          app_name: app_name,
          instance_id: instance_id,
        }
      ),
      meta: MapSet.new([])
    }

    cf_username = System.get_env("LIBCLUSTER_CF_USERNAME")
    cf_password = System.get_env("LIBCLUSTER_CF_PASSWORD")
    {_, 0} = System.cmd("#{System.cwd}/cf", ["login", "-a", cf_api_base_uri, "-u", cf_username, "-p", cf_password])

    {:ok, state, 0}
  end

  def handle_info(:timeout, state) do
    handle_info(:load, state)
  end
  def handle_info(:load, %State{topology: topology, connect: connect, disconnect: disconnect, list_nodes: list_nodes} = state) do
    new_nodelist = MapSet.new(get_nodes(state))
    added        = MapSet.difference(new_nodelist, state.meta)
    removed      = MapSet.difference(state.meta, new_nodelist)
    new_nodelist = case Cluster.Strategy.disconnect_nodes(topology, disconnect, list_nodes, MapSet.to_list(removed)) do
                :ok ->
                  new_nodelist
                {:error, bad_nodes} ->
                  # Add back the nodes which should have been removed, but which couldn't be for some reason
                  Enum.reduce(bad_nodes, new_nodelist, fn {n, _}, acc ->
                    MapSet.put(acc, n)
                  end)
              end
    new_nodelist = case Cluster.Strategy.connect_nodes(topology, connect, list_nodes, MapSet.to_list(added)) do
              :ok ->
                new_nodelist
              {:error, bad_nodes} ->
                # Remove the nodes which should have been added, but couldn't be for some reason
                Enum.reduce(bad_nodes, new_nodelist, fn {n, _}, acc ->
                  MapSet.delete(acc, n)
                end)
            end
    Process.send_after(self(), :load, Map.get(state.config, :polling_interval, @default_polling_interval))
    {:noreply, %{state | :meta => new_nodelist}}
  end

  def handle_info(_, state) do
    {:noreply, state}
  end

  @spec get_nodes(State.t) :: [atom()]
  defp get_nodes(%State{topology: topology, config: config}) do
    instance_id = config.instance_id
    app_name = config.app_name
    case instance_id do
      0 ->
        []
      id ->
        0..(id-1)
        |> Enum.map(fn(i) ->
          case System.cmd("#{System.cwd}/cf", ["ssh", app_name, "-i", "#{i}", "-c", "echo $CF_INSTANCE_INTERNAL_IP" ]) do
            {ip, 0} ->
              ip = String.trim(ip)
              warn topology, "#{:erlang.node}: discovered ip #{ip} for instance #{i}"
              {i, ip}
            {body, code} ->
              warn topology, "#{:erlang.node}: cannot cf ssh to instance #{i} (#{code}): #{body}"
              nil
          end
        end)
        |> Enum.reject(fn(ip) -> ip == nil end)
        |> Enum.map(fn({i, ip}) -> IO.inspect(:"app#{i}@#{ip}") end)
    end
  end
end
