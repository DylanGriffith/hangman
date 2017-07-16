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
end
