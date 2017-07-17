defmodule HangmanServer.Game.Logic do
  @wrong_guess_limit 8

  def guess(state, letter) do
    %{
      word: word,
      guessed: guessed,
      status: status,
      next_words: next_words,
    } = state
    word_chars = word_to_chars(word)
    new_guessed = MapSet.put(guessed, letter)
    cond do
      status == "succeeded" || status == "failed" ->
        [word | next_words] = next_words
        %{state | word: word, guessed: MapSet.new([letter]), status: "progress", next_words: next_words}
      too_many_guesses?(word_chars, new_guessed) -> %{state | guessed: new_guessed, status: "failed"}
      all_guessed?(word_chars, new_guessed) -> %{state | guessed: new_guessed, status: "succeeded"}
      true -> %{state | guessed: new_guessed}
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
