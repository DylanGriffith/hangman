defmodule HangmanServer.Application do
  use Application

  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    port = elem(Integer.parse(System.get_env("PORT") || "4001"), 0)
     children = [
       Plug.Adapters.Cowboy.child_spec(:http, HangmanServer.Web.Router, [], [port: port]),
       supervisor(Registry, [:unique, :sessions_process_registry]),
       supervisor(HangmanServer.Session.Supervisor, []),
       worker(HangmanServer.ScoreKeeper, []),
       worker(HangmanServer.WordSuggestor, []),
     ]

      opts = [strategy: :one_for_one, name: HangmanServer.Supervisor]
      Supervisor.start_link(children, opts)
  end
end
