use Mix.Config

defmodule WordSuggestorMock do
  def suggest do
    "cat"
  end
end

config :hangman_server,
  words_per_session: 2,
  word_suggestor: WordSuggestorMock,
  redis_prefix: "hangman-test:"
