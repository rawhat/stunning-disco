defmodule Codisco.WsRouter do

  @behaviour :cowboy_websocket

  def init(req, state) do
    IO.inspect req
    #{:cowboy_websocket, req, state}
    {:upgrade, :protocol, :cowboy_websocket}
  end

  def websocket_init(_type, req, _opts) do
    IO.inspect req
    {:ok, req, %{}}
  end

  def websocket_handle({:text, message}, state) do
    msg = Poison.decode!(message)
    IO.puts "got ws message: #{msg}"
    {:reply, "hi", state}
  end
end
