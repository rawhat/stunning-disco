defmodule Codisco.Router do
  use Plug.Router
  use Plug.Debugger
  require Logger

  plug(Plug.Logger, log: :debug)

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "hello, world")
  end

  get "/*path" do
    send_resp(conn, 404, "Not found")
  end
end
