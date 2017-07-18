defmodule HangmanServer.WordSuggestor do
  use GenServer

  # API
  def start_link do
    GenServer.start_link(__MODULE__, [], name: __MODULE__)
  end

  def suggest do
    GenServer.call(__MODULE__, :suggest)
  end

  # Callbacks
  def init([]) do
    GenServer.cast(self(), :load_file)

    {:ok, []}
  end

  def handle_cast(:load_file, _) do
    words = load_words_from_file()
    {:noreply, words}
  end

  def handle_call(:suggest, _from, words) do
    limit = map_size(words)
    index = :rand.uniform(limit) - 1
    {:reply, Map.get(words, index), words}
  end

  defp load_words_from_file do
    {:ok, body} = File.read("words_alpha.txt")
    body
    |> String.split("\r\n")
    |> Enum.with_index
    |> Enum.reduce(%{}, fn({word, index}, acc) ->
      Map.put(acc, index, word)
    end)
  end
end
