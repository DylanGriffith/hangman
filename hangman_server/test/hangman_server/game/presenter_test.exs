defmodule HangmanServer.Game.PresenterTest do
  use ExUnit.Case
  import HangmanServer.Game.Presenter

  test "#obscure_word - uses underscores for unguessed letters" do
    assert obscure_word("cat", MapSet.new(["a"])) == "_a_"
    assert obscure_word("cat", MapSet.new(["a", "d"])) == "_a_"
    assert obscure_word("cat", MapSet.new(["a", "d", "c"])) == "ca_"
    assert obscure_word("cat", MapSet.new(["a", "d", "t"])) == "_at"
    assert obscure_word("cat", MapSet.new(["a", "d", "t", "c"])) == "cat"
    assert obscure_word("cat", MapSet.new(["f", "d", "t", "c"])) == "c_t"
  end
end
