defmodule HangmanServer.Game.Presenter do
  def obscure_word(word, guessed_letters) do
    Enum.map(String.graphemes(word), fn (c) ->
      case MapSet.member?(guessed_letters, c) do
        true -> c
        _ -> "_"
      end
    end) |> Enum.join("")
  end
end
