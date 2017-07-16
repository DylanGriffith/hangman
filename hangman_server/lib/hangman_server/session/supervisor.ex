defmodule HangmanServer.Session.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def start_session(username) do
    session_id = random_session_id()
    {:ok, _} = Supervisor.start_child(__MODULE__, [{username, session_id}])
    HangmanServer.Session.Session.state(session_id)
  end

  def init(:ok) do
    children = [
      worker(HangmanServer.Session.Session, [], restart: :transient),
    ]

    supervise(children, strategy: :simple_one_for_one)
  end

  defp random_session_id do
    :crypto.strong_rand_bytes(16)
    |> :erlang.bitstring_to_list
    |> Enum.map(fn (x) -> :erlang.integer_to_binary(x, 16) end)
    |> Enum.join
    |> String.downcase
  end
end
