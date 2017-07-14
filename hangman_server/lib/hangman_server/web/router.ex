defmodule HangmanServer.Web.Router do
  use Plug.Router

  plug :match
  plug :dispatch

  post "/api/sessions" do
    response = %{
      sessionId: "abc123",
    }
    send_resp(conn, 201, Poison.encode!(response))
  end
end
