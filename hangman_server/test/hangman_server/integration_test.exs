defmodule HangmanServer.IntegrationTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts HangmanServer.Web.Router.init([])

  test "create a new session" do
    conn = conn(:post, "/api/sessions", ~s|{"username": "alice"}|)
           |> put_req_header("content-type", "application/json")
    conn = HangmanServer.Web.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 201

    data = Poison.decode!(conn.resp_body, keys: :atoms!)
    assert data.username == "alice"
    assert data.session_id =~ ~r/.+/
    assert data.word =~ ~r/^[_ ]+$/
  end
end
