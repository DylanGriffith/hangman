defmodule HangmanServer.ScoreKeeper do
  use GenServer

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

  # Callbacks
  def init([]) do
    GenServer.cast(self(), :connect_to_redis)
    {:ok, nil}
  end

  def handle_cast(:connect_to_redis, state) do
    {:ok, conn} = if System.get_env("VCAP_SERVICES") do
      hostname = System.get_env("VCAP_SERVICES")["rediscloud"]["hostname"]
      port = System.get_env("VCAP_SERVICES")["rediscloud"]["port"]
      password = System.get_env("VCAP_SERVICES")["rediscloud"]["password"]
      Redix.start_link(host: hostname, port: port, password: password)
    else
      Redix.start_link()
    end
    {:noreply, conn}
  end

  def handle_cast({:register_score, username, total_score}, conn) do
    {:ok, score} = Redix.command(conn, ["HGET", "hangman-high-scores", username])
    if !score do
      {:ok, _} = Redix.command(conn, ["HSET", "hangman-high-scores", username, total_score])
    else
      {score, ""} = Integer.parse(score)
      if total_score > score do
        {:ok, _} = Redix.command(conn, ["HSET", "hangman-high-scores", username, total_score])
      end
    end

    {:noreply, conn}
  end

  def handle_call(:get_high_scores, _from, conn) do
    {:reply, state.high_scores, conn}
  end
end
