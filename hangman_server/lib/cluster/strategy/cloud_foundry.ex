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

  @default_polling_interval 5_000

  def start_link(opts), do: GenServer.start_link(__MODULE__, opts)
  def init(opts) do
    vcap_application = Poison.decode!(System.get_env("VCAP_APPLICATION"))
    cf_api_base_uri = vcap_application["cf_api"]
    cf_username = System.get_env("LIBCLUSTER_CF_USERNAME")
    cf_password = System.get_env("LIBCLUSTER_CF_PASSWORD")
    app_guid = vcap_application["application_id"]
    config = Keyword.fetch!(opts, :config)

    state = %State{
      topology: Keyword.fetch!(opts, :topology),
      connect: Keyword.fetch!(opts, :connect),
      disconnect: Keyword.fetch!(opts, :disconnect),
      list_nodes: Keyword.fetch!(opts, :list_nodes),
      config: %{
        config |
        vcap_application: vcap_application,
        cf_api_base_uri: cf_api_base_uri,
        cf_username: cf_username,
        cf_password: cf_username,
        app_guid: app_guid,
      },
      meta: MapSet.new([])
    }
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
    Process.send_after(self(), :load, Keyword.get(state.config, :polling_interval, @default_polling_interval))
    {:noreply, %{state | :meta => new_nodelist}}
  end
  def handle_info(_, state) do
    {:noreply, state}
  end

  #@spec get_token(Map) :: String.t
  defp get_token(config) do
    %{
        cf_api_base_uri: cf_api_base_uri,
        cf_username: cf_username,
        cf_password: cf_password,
    } = config

    case get_login_base_url(cf_api_base_uri) do
      {:ok, login_base_url} ->
        headers = [
          {'accept', 'application/json'},
        ]
        uri_encoded_username = URI.encode(cf_username)
        req_body = 'grant_type=password&password=#{cf_password}&scope=&username=#{uri_encoded_username}'
        case :httpc.request(:post, {'#{login_base_url}/oauth/token', headers, 'application/x-www-form-urlencoded', req_body}, [], []) do
          {:ok, {{_version, 200, _status}, _headers, body}} ->
            Poison.decode!(body)["access_token"]
          {:ok, {{_version, 403, _status}, _headers, body}} ->
            %{"message" => msg} = Poison.decode!(body)
            warn cf_api_base_uri, "cannot query cloudfoundry (unauthorized): #{msg}"
            nil
          {:ok, {{_version, code, status}, _headers, body}} ->
            warn cf_api_base_uri, "cannot query cloudfoundry (#{code} #{status}): #{inspect body}"
            nil
          {:error, reason} ->
            error cf_api_base_uri, "request to cloudfoundry failed!: #{inspect reason}"
            nil
        end
      _ -> nil
    end
  end

  defp get_login_base_url(cf_api_base_uri) do
    headers = [
      {'accept', 'application/json'},
    ]
    case :httpc.request(:get, {'#{cf_api_base_uri}/login', headers}, [], []) do
      {:ok, {{_version, 200, _status}, _headers, body}} ->
        data = Poison.decode!(body)
        {:ok, data["login"]}
      {:ok, {{_version, 403, _status}, _headers, body}} ->
        %{"message" => msg} = Poison.decode!(body)
        warn cf_api_base_uri, "cannot query cloudfoundry (unauthorized): #{msg}"
        {:error, "unauthorized"}
      {:ok, {{_version, code, status}, _headers, body}} ->
        warn cf_api_base_uri, "cannot query cloudfoundry (#{code} #{status}): #{inspect body}"
        {:error, "cf unexpected response"}
      {:error, reason} ->
        error cf_api_base_uri, "request to cloudfoundry failed!: #{inspect reason}"
        {:error, "cf request failure"}
    end
  end

  @spec get_nodes(State.t) :: [atom()]
  defp get_nodes(%State{topology: topology, config: config}) do
    token     = get_token(config)
    app_guid = Keyword.fetch!(config, :app_guid)
    cf_api_base_uri = Keyword.fetch!(config, :cf_api_base_uri)
    cond do
      app_guid != nil and cf_api_base_uri != nil and token != nil ->
        endpoints_path = "/v2/apps/#{app_guid}/stats"
        headers        = [{'authorization', 'Bearer #{token}'}]
        http_options   = [ssl: [verify: :verify_none]]
        case :httpc.request(:get, {'#{cf_api_base_uri}/#{endpoints_path}', headers}, http_options, []) do
          {:ok, {{_version, 200, _status}, _headers, body}} ->
            parse_nodes(body)
          {:ok, {{_version, 403, _status}, _headers, body}} ->
            %{"message" => msg} = Poison.decode!(body)
            warn topology, "cannot query kubernetes (unauthorized): #{msg}"
            []
          {:ok, {{_version, code, status}, _headers, body}} ->
            warn topology, "cannot query kubernetes (#{code} #{status}): #{inspect body}"
            []
          {:error, reason} ->
            error topology, "request to kubernetes failed!: #{inspect reason}"
            []
        end
      app_guid == nil ->
        warn "foobar", "kubernetes strategy is selected, but :kubernetes_node_basename is not configured!"
        []
      cf_api_base_uri == nil ->
        warn "foobar", "kubernetes strategy is selected, but :kubernetes_selector is not configured!"
        []
      token == nil ->
        warn "foobar", "kubernetes strategy is selected, but :kubernetes_selector is not configured!"
        []
      :else ->
        warn "foobar", "kubernetes strategy is selected, but is not configured!"
        []
    end
  end

  def parse_nodes(response) do
    data = Poison.decode!(response)
    data |> Enum.map(fn({instance_id, data}) ->
      ip_addr = data["stats"]["host"]
      :"app#{instance_id}@#{ip_addr}"
    end)
  end
end
