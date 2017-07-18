defmodule HangmanServer.IntegrationTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts HangmanServer.Web.Router.init([])

  test "play" do
    # Create a session
    conn = conn(:post, "/api/sessions", ~s|{"username": "alice"}|)
           |> put_req_header("content-type", "application/json")
    conn = HangmanServer.Web.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 201

    data = Poison.decode!(conn.resp_body, keys: :atoms!)
    session_id = data.session_id
    orig_word = data.word
    assert data.username == "alice"
    assert session_id =~ ~r/.+/
    assert data.status == "progress"
    assert orig_word =~ ~r/^[_ ]+$/
    assert data.next_word =~ ~r/^[_ ]+$/
    assert data.total_score == 0

    # Make a guess
    conn = conn(:put, "/api/sessions/#{session_id}/guess/a")
           |> put_req_header("content-type", "application/json")
    conn = HangmanServer.Web.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 200

    data = Poison.decode!(conn.resp_body, keys: :atoms!)
    assert data.word =~ ~r/^[_ a]+$/
    assert String.length(data.word) == String.length(orig_word)
    assert data.status == "progress"
    assert data.next_word =~ ~r/^[_ ]+$/
    assert data.total_score == 0

    # Make the rest of the guesses
    rest = ["b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z", "a", "b", "c", "d", "e", "f", "g", "h", "i", "j", "k", "l", "m", "n", "o", "p", "q", "r", "s", "t", "u", "v", "w", "x", "y", "z"]
    Enum.each(rest, fn(letter) ->
      conn(:put, "/api/sessions/#{session_id}/guess/#{letter}")
      |> put_req_header("content-type", "application/json")
      |> HangmanServer.Web.Router.call(@opts)
    end)

    # Check high scores
    conn = conn(:get, "/api/high_scores")
           |> HangmanServer.Web.Router.call(@opts)
    assert conn.state == :sent
    assert conn.status == 200

    data = Poison.decode!(conn.resp_body)
    assert data["alice"] != nil
    assert data["alice"] >= 0
  end

  test "invalid guess" do
    # Create a session
    conn = conn(:post, "/api/sessions", ~s|{"username": "alice"}|)
           |> put_req_header("content-type", "application/json")
    conn = HangmanServer.Web.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 201

    data = Poison.decode!(conn.resp_body, keys: :atoms!)
    session_id = data.session_id

    conn = conn(:put, "/api/sessions/#{session_id}/guess/_")
           |> put_req_header("content-type", "application/json")
    conn = HangmanServer.Web.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 400

    conn = conn(:put, "/api/sessions/#{session_id}/guess/ab")
           |> put_req_header("content-type", "application/json")
    conn = HangmanServer.Web.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 400
  end
end
