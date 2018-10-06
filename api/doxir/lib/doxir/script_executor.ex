defmodule Doxir.ScriptExecutor do

  use GenServer

  def start_link(_args) do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_args) do
    channel = connect_to_amqp({})
    {:ok, %{channel: channel}}
  end

  def connect_to_amqp({:ok, channel}), do: channel
  def connect_to_amqp(_) do
    conn = AMQP.Connection.open(host: "queue")
    case conn do
      {:ok, connection} ->
        {:ok, channel} = AMQP.Channel.open(connection)
        #AMQP.Queue.declare(channel, "commands")
        connect_to_amqp({:ok, channel})
      _ ->
        :timer.sleep(1000)
        connect_to_amqp({:err})
    end
  end

  def handle_call({:exec_script, language, script, username}, _from, state) do
    {:ok, connection} = AMQP.Connection.open(host: "queue")
    {:ok, channel} = AMQP.Channel.open(connection)
    body = Poison.encode!(%{language: language, script: script, username: username})
    #AMQP.Basic.publish(channel, "", "commands", body)
    resp = AMQP.Basic.publish(channel, "", "commands", body)
    IO.puts "Hello we are in here"
    IO.inspect resp
    {:reply, :ok, state}
  end
end
