defmodule HangmanServer.Game.LogicTest do
  use ExUnit.Case
  import HangmanServer.Game.Logic

  test "#guess - to succeeded" do
    state = %{
      word: "cat",
      guessed: MapSet.new(["a"]),
      status: "progress",
    }

    assert guess(state, "t") == %{
      word: "cat",
      guessed: MapSet.new(["a", "t"]),
      status: "progress",
    }

    assert guess(guess(state, "t"), "c") == %{
      word: "cat",
      guessed: MapSet.new(["c", "a", "t"]),
      status: "succeeded",
    }
  end

  test "#guess - to failed" do
    state = %{
      word: "cat",
      guessed: MapSet.new(["a", "b", "c", "d", "e", "f", "g", "h", "i"]),
      status: "progress",
    }

    assert guess(state, "j") == %{
      word: "cat",
      guessed: MapSet.new([]),
      status: "failed",
    }
  end
end
