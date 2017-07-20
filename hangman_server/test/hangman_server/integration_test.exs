defmodule HangmanServer.IntegrationTest do
  use ExUnit.Case, async: true
  use Plug.Test

  @opts HangmanServer.Web.Router.init([])

  test "guess cat" do
    :ok = HangmanServer.ScoreKeeper.clear_all

    # Create a session
    conn = conn(:post, "/api/sessions", ~s|{"username": "cat-guesser"}|)
           |> put_req_header("content-type", "application/json")
    conn = HangmanServer.Web.Router.call(conn, @opts)

    assert conn.state == :sent
    assert conn.status == 201

    data = Poison.decode!(conn.resp_body, keys: :atoms!)
    session_id = data.session_id
    orig_word = data.word
    assert data.username == "cat-guesser"
    assert session_id =~ ~r/.+/
    assert data.status == "progress"
    assert orig_word =~ ~r/___/
    assert data.next_word =~ ~r/___/
    assert data.total_score == 0

    # Guess first cat
    conn = conn(:put, "/api/sessions/#{session_id}/guess/c")
           |> put_req_header("content-type", "application/json")
           |> HangmanServer.Web.Router.call(@opts)

    data = Poison.decode!(conn.resp_body, keys: :atoms!)
    assert data.status == "progress"
    assert data.word =~ ~r/c__/
    assert data.next_word =~ ~r/___/

    conn = conn(:put, "/api/sessions/#{session_id}/guess/a")
           |> put_req_header("content-type", "application/json")
           |> HangmanServer.Web.Router.call(@opts)

    data = Poison.decode!(conn.resp_body, keys: :atoms!)
    assert data.status == "progress"
    assert data.word =~ ~r/ca_/
    assert data.next_word =~ ~r/___/

    conn = conn(:put, "/api/sessions/#{session_id}/guess/t")
           |> put_req_header("content-type", "application/json")
           |> HangmanServer.Web.Router.call(@opts)

    data = Poison.decode!(conn.resp_body, keys: :atoms!)
    assert data.status == "succeeded"
    assert data.word =~ ~r/cat/
    assert data.next_word =~ ~r/___/

    # Check high score
    conn = conn(:get, "/api/high_scores")
           |> HangmanServer.Web.Router.call(@opts)
    assert conn.state == :sent
    assert conn.status == 200

    data = Poison.decode!(conn.resp_body)
    assert data["cat-guesser"] == 1

    # Guess second cat
    conn = conn(:put, "/api/sessions/#{session_id}/guess/c")
           |> put_req_header("content-type", "application/json")
           |> HangmanServer.Web.Router.call(@opts)

    data = Poison.decode!(conn.resp_body, keys: :atoms!)
    assert data.status == "progress"
    assert data.word =~ ~r/c__/
    assert data.next_word == nil

    conn = conn(:put, "/api/sessions/#{session_id}/guess/t")
           |> put_req_header("content-type", "application/json")
           |> HangmanServer.Web.Router.call(@opts)

    data = Poison.decode!(conn.resp_body, keys: :atoms!)
    assert data.status == "progress"
    assert data.word =~ ~r/c_t/
    assert data.next_word == nil

    conn = conn(:put, "/api/sessions/#{session_id}/guess/a")
           |> put_req_header("content-type", "application/json")
           |> HangmanServer.Web.Router.call(@opts)

    data = Poison.decode!(conn.resp_body, keys: :atoms!)
    assert data.status == "succeeded"
    assert data.word =~ ~r/cat/
    assert data.next_word == nil

    # Run out of words
    conn = conn(:put, "/api/sessions/#{session_id}/guess/t")
           |> put_req_header("content-type", "application/json")
           |> HangmanServer.Web.Router.call(@opts)

    assert conn.state == :sent
    assert conn.status == 200

    data = Poison.decode!(conn.resp_body, keys: :atoms!)
    assert data.status == "out_of_words"
    assert data.total_score == 2

    # Check high score
    conn = conn(:get, "/api/high_scores")
           |> HangmanServer.Web.Router.call(@opts)
    assert conn.state == :sent
    assert conn.status == 200

    data = Poison.decode!(conn.resp_body)
    assert data["cat-guesser"] == 2
  end
end
