defmodule HangmanServer.Web.Router do
  use Plug.Router

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
    response = HangmanServer.Session.Session.guess(
      conn.path_params["session_id"],
      conn.path_params["letter"]
    )
    send_resp(conn, 200, Poison.encode!(response))
  end
end
