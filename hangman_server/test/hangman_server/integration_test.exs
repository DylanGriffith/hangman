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
  end
end
