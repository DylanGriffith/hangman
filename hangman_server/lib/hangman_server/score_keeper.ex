defmodule HangmanServer.ScoreKeeper do
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
    {:ok, %{
      high_scores: %{}
    }}
  end

  def handle_cast({:register_score, username, total_score}, state) do
    new_state = %{
      state |
      high_scores: Map.update(state.high_scores, username, 0, fn(prev) ->
        cond do
          total_score > prev -> total_score
          true -> prev
        end
      end)
    }
    {:noreply, new_state}
  end

  def handle_call(:get_high_scores, _from, state) do
    {:reply, state.high_scores, state}
  end
end
