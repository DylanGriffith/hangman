defmodule HangmanServer.Session.Session do
  alias HangmanServer.Game.Presenter
  use GenServer

  @word_suggestor Application.get_env(:hangman_server, :word_suggestor)

  # API
  def start_link({username, session_id}) do
    GenServer.start_link(__MODULE__, {username, session_id}, name: via_tuple(session_id))
  end

  def state(session_id) when is_binary(session_id) do
    GenServer.call(via_tuple(session_id), :state)
  end

  def guess(session_id, letter) when is_binary(session_id) do
    GenServer.call(via_tuple(session_id), {:guess, letter})
  end

  # Callbacks
  def init({username, session_id}) do
    limit = Application.get_env(:hangman_server, :words_per_session) - 1
    [word | next_words] = 0..limit |> Enum.map(fn(_) ->
      @word_suggestor.suggest
    end)
    Process.send_after(self(), :timeout, 60 * 1000)
    {:ok, %{
      username: username,
      session_id: session_id,
      word: word,
      guessed: MapSet.new(),
      status: "progress",
      next_words: next_words,
      started_at: now(),
      total_score: 0,
    }}
  end

  def handle_call(:state, _from, state) do
    {:reply, present(state), state}
  end

  def handle_call({:guess, letter}, _from, state) do
    state = cond do
      state.status == "timeout" ->
        state
      state.status == "out_of_words" ->
        state
      state.next_words == [] && state.status != "progress" ->
        %{state | status: "out_of_words"}
      true ->
        %{
          word: word,
          guessed: guessed,
          status: status,
          next_words: next_words,
        } = HangmanServer.Game.Logic.guess(
          %{
            word: state.word,
            guessed: state.guessed,
            status: state.status,
            next_words: state.next_words,
          },
          letter
        )
        total_score = case status do
          "succeeded" ->
            GenServer.cast(self(), :register_score)
            state.total_score + 1
          _ ->
            state.total_score
        end
        %{
          state |
          word: word,
          guessed: guessed,
          status: status,
          next_words: next_words,
          total_score: total_score,
        }
    end

    {:reply, present(state), state}
  end

  defp via_tuple(session_id) do
    {:via, Registry, {:sessions_process_registry, session_id}}
  end

  defp present(state) do
    next_word = case state.next_words do
      [h | _] -> h
      _ -> nil
    end

    %{
      word: Presenter.obscure_word(state.word, state.guessed),
      username: state.username,
      session_id: state.session_id,
      status: state.status,
      next_word: next_word && Presenter.obscure_word(next_word, MapSet.new),
      total_score: state.total_score,
    }
  end

  def handle_cast(:register_score, state) do
    HangmanServer.ScoreKeeper.register_score(state.username, state.total_score)
    {:noreply, state}
  end

  def handle_info(:shutdown, state) do
    {:stop, :normal, state}
  end

  def handle_info(:timeout, state) do
    Process.send_after(self(), :shutdown, 30 * 1000)
    {:stop, :normal, %{state | status: "timeout"}}
  end

  defp now do
    DateTime.to_unix(DateTime.utc_now)
  end
end
