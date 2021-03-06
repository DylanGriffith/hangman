defmodule HangmanServer.Web.Router do
  use Plug.Router

  plug CORSPlug, origin: ~r/.*/

  plug Plug.Parsers,
    parsers: [:json],
    pass:  ["text/*"],
    json_decoder: Poison

  plug :match
  plug :dispatch

  post "/api/sessions" do
    username = conn.body_params["username"]
    response = HangmanServer.Session.Supervisor.start_session(username)
    send_resp(conn, 201, Poison.encode!(response))
  end

  put "/api/sessions/:session_id/guess/:letter" do
    letter = conn.path_params["letter"]
    cond do
      letter =~ ~r/^[a-z]$/ ->
        response = HangmanServer.Session.Session.guess(
          conn.path_params["session_id"],
          conn.path_params["letter"]
        )
        send_resp(conn, 200, Poison.encode!(response))
      true ->
        send_resp(conn, 400, Poison.encode!(%{error: "letter must be a-z and one character"}))
    end
  end

  get "/api/high_scores" do
    {:ok, high_scores} = HangmanServer.ScoreKeeper.get_high_scores
    send_resp(conn, 200, Poison.encode!(high_scores))
  end
end
