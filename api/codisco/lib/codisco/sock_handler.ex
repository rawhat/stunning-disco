defmodule Codisco.SockHandler do

  use GenServer

  def start_link(_args) do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_args) do
    {:ok, %{}}
  end

  def handle_call({:new_user, username, socket}, _from, state) do
    {:reply, :ok, %{state | username: socket}}
  end

  def handle_call({:log_received, username, log}, _from, state) do
    IO.puts "sending: #{log} to #{username}"
    {:reply, :ok, state}
  end
end
