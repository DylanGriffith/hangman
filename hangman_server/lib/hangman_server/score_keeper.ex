defmodule HangmanServer.ScoreKeeper do
  use GenServer
  @redis_key "#{Application.get_env(:hangman_server, :redis_prefix)}high-scores"

  # API
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def register_score(username, total_score) do
    GenServer.cast(__MODULE__, {:register_score, username, total_score})
  end

  def get_high_scores do
    GenServer.call(__MODULE__, :get_high_scores)
  end

  def clear_all do
    GenServer.call(__MODULE__, :clear_all)
  end

  # Callbacks
  def init([]) do
    GenServer.cast(self(), :connect_to_redis)
    {:ok, nil}
  end

  def handle_cast(:connect_to_redis, _) do
    {:ok, conn} = if System.get_env("VCAP_SERVICES") do
      hostname = System.get_env("VCAP_SERVICES")["rediscloud"]["hostname"]
      port = System.get_env("VCAP_SERVICES")["rediscloud"]["port"]
      password = System.get_env("VCAP_SERVICES")["rediscloud"]["password"]
      Redix.start_link(host: hostname, port: port, password: password)
    else
      if System.get_env("REDIS_URL") do
        Redix.start_link(System.get_env("REDIS_URL"))
      else
        Redix.start_link()
      end
    end
    {:noreply, conn}
  end

  def handle_cast({:register_score, username, total_score}, conn) do
    {:ok, score} = Redix.command(conn, ["HGET", @redis_key, username])
    if !score do
      {:ok, _} = Redix.command(conn, ["HSET", @redis_key, username, total_score])
    else
      {score, ""} = Integer.parse(score)
      if total_score > score do
        {:ok, _} = Redix.command(conn, ["HSET", @redis_key, username, total_score])
      end
    end

    {:noreply, conn}
  end

  def handle_call(:get_high_scores, _from, conn) do
    {:ok, scores_list} = Redix.command(conn, ["HGETALL", @redis_key])
    high_scores = parse_scores_list(scores_list, %{})
    {:reply, {:ok, high_scores}, conn}
  end

  def handle_call(:clear_all, _from, conn) do
    {:ok, _} = Redix.command(conn, ["DEL", @redis_key])
    {:reply, :ok, conn}
  end

  defp parse_scores_list([], acc) do
    acc
  end

  defp parse_scores_list([k, v | rest], acc) do
    {int_value, ""} = Integer.parse(v)
    parse_scores_list(rest, Map.put(acc, k, int_value))
  end
end
