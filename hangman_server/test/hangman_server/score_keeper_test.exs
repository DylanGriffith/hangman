defmodule HangmanServer.ScoreKeeperTest do
  use ExUnit.Case, async: true
  use Plug.Test

  test "register_score" do
    {:noreply, new_state} = HangmanServer.ScoreKeeper.handle_cast({:register_score, "bob", 3}, %{high_scores: %{}})
    assert new_state.high_scores["bob"] == 3

    {:noreply, new_state} = HangmanServer.ScoreKeeper.handle_cast({:register_score, "bob", 3}, %{high_scores: %{"bob" => 4}})
    assert new_state.high_scores["bob"] == 4

    {:noreply, new_state} = HangmanServer.ScoreKeeper.handle_cast({:register_score, "bob", 3}, %{high_scores: %{"bob" => 2}})
    assert new_state.high_scores["bob"] == 3
  end
end
