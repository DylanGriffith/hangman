defmodule HangmanServer.Game.LogicTest do
  use ExUnit.Case
  import HangmanServer.Game.Logic

  test "#guess - to succeeded" do
    state = %{
      word: "cat",
      guessed: MapSet.new(["a"]),
      status: "progress",
      next_words: ["dog"],
    }

    assert guess(state, "t") == %{
      word: "cat",
      guessed: MapSet.new(["a", "t"]),
      status: "progress",
      next_words: ["dog"],
    }

    assert guess(guess(state, "t"), "c") == %{
      word: "cat",
      guessed: MapSet.new(["c", "a", "t"]),
      status: "succeeded",
      next_words: ["dog"],
    }

    assert guess(guess(guess(state, "t"), "c"), "d") == %{
      word: "dog",
      guessed: MapSet.new(["d"]),
      status: "progress",
      next_words: [],
    }
  end

  test "#guess - to failed" do
    state = %{
      word: "cat",
      guessed: MapSet.new(["a", "b", "c", "d", "e", "f", "g", "h", "i"]),
      status: "progress",
      next_words: ["dog"],
    }

    assert guess(state, "j") == %{
      word: "cat",
      guessed: MapSet.new(["a", "b", "c", "d", "e", "f", "g", "h", "i", "j"]),
      status: "failed",
      next_words: ["dog"],
    }

    assert guess(guess(state, "j"), "d") == %{
      word: "dog",
      guessed: MapSet.new(["d"]),
      status: "progress",
      next_words: [],
    }
  end
end
