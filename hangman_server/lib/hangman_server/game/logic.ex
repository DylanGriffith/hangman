defmodule HangmanServer.Game.Logic do
  @wrong_guess_limit 8

  def guess(%{word: word, guessed: guessed, status: status}, letter) do
    word_chars = word_to_chars(word)
    new_guessed = MapSet.put(guessed, letter)
    cond do
      too_many_guesses?(word_chars, new_guessed) -> %{word: word, guessed: MapSet.new, status: "failed"}
      all_guessed?(word_chars, new_guessed) -> %{word: word, guessed: new_guessed, status: "succeeded"}
      true -> %{word: word, guessed: new_guessed, status: status}
    end
  end

  defp word_to_chars(word) do
    word
    |> String.graphemes
    |> Enum.filter(fn(c) -> c != " " end)
    |> MapSet.new
  end

  defp too_many_guesses?(word_chars, guessed) do
    MapSet.difference(guessed, word_chars) |> MapSet.size >= @wrong_guess_limit
  end

  defp all_guessed?(word_chars, guessed) do
    MapSet.subset?(word_chars, guessed)
  end
end
