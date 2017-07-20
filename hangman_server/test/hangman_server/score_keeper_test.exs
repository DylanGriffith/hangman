defmodule HangmanServer.ScoreKeeperTest do
  alias HangmanServer.ScoreKeeper
  use ExUnit.Case, async: true
  use Plug.Test

  test "register_score" do
    :ok = ScoreKeeper.clear_all

    ScoreKeeper.register_score("bob", 3)
    {:ok, high_scores} = ScoreKeeper.get_high_scores
    assert high_scores["bob"] == 3

    ScoreKeeper.register_score("bob", 4)
    {:ok, high_scores} = ScoreKeeper.get_high_scores
    assert high_scores["bob"] == 4

    ScoreKeeper.register_score("bob", 2)
    {:ok, high_scores} = ScoreKeeper.get_high_scores
    assert high_scores["bob"] == 4
  end
end
