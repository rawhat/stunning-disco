defmodule DoxirWeb.CodeController do
  use DoxirWeb, :controller

  def index(conn, _params) do
    conn |> send_resp(200, "hello, world")
  end

  def submit(conn, params) do
    %{"language" => language, "script" => script, "username" => username} = params
    # send this to the message queue
    IO.inspect conn.body_params
    resp = GenServer.call(Doxir.ScriptExecutor, {:exec_script, language, script, username})
    IO.inspect resp
    conn
    |> send_resp(200, "Ok")
  end
end
