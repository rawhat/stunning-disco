defmodule Doxir.LogReader do
  def start do
    connect_to_amqp(:err)
    wait_for_messages()
  end

  def connect_to_amqp(:ok), do: :ok
  def connect_to_amqp(_) do
    conn = AMQP.Connection.open(host: "queue")
    case conn do
      {:ok, connection} ->
        {:ok, channel} = AMQP.Channel.open(connection)
        AMQP.Queue.declare(channel, "logs")
        AMQP.Basic.consume(channel, "logs", nil, no_ack: true)
        IO.puts "consuming logs"
        connect_to_amqp(:ok)
      _ ->
        :timer.sleep(1000)
        connect_to_amqp(:err)
    end
  end

  def forward_to_websocket(username, log) do
    IO.puts "got: #{log} from #{username}"
    GenServer.call(Doxir.SockHandler, {:log_received, username, log})
  end

  def wait_for_messages() do
    receive do
      {:basic_deliver, payload, _meta} ->
        IO.puts " [x] Received #{payload}"
        %{"log" => log, "username" => username} = Poison.decode!(payload)
        forward_to_websocket(username, log)
        wait_for_messages()
    end
  end
end
