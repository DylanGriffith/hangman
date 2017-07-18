defmodule HangmanServer.ScoreKeeper do
  use GenServer

  # API
  def start_link do
    GenServer.start_link(__MODULE__, [], name: via_tuple())
  end

  def register_score(username, total_score) do
    GenServer.cast(via_tuple(), {:register_score, username, total_score})
  end

  def get_high_scores do
    GenServer.call(via_tuple(), :get_high_scores)
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
      high_scores: Map.update(state.high_scores, username, total_score, fn(prev) ->
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

  defp via_tuple do
    {:via, :swarm, "score-keeper"}
  end
end
