defmodule HangmanServer.Session.Session do
  alias HangmanServer.Game.Presenter
  use GenServer

  # API
  def start_link({username, session_id}) do GenServer.start_link(__MODULE__, {username, session_id}, name: via_tuple(session_id))
  end

  def state(session_id) when is_binary(session_id) do
    GenServer.call(via_tuple(session_id), :state)
  end

  def guess(session_id, letter) when is_binary(session_id) do
    GenServer.call(via_tuple(session_id), {:guess, letter})
  end

  # Callbacks
  def init({username, session_id}) do
    {:ok, %{
      username: username,
      session_id: session_id,
      word: "cat",
      guessed: MapSet.new(),
    }}
  end

  def handle_call(:state, _from, state) do
    {:reply, present(state), state}
  end

  def handle_call({:guess, letter}, _from, state) do
    {:reply, present(state), state}
  end

  defp via_tuple(session_id) do
    {:via, Registry, {:sessions_process_registry, session_id}}
  end

  defp present(state) do
    %{
      word: Presenter.obscure_word(state.word, state.guessed),
      username: state.username,
      session_id: state.session_id,
    }
  end
end
