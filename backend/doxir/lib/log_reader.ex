defmodule Doxir.LogReader do

  use GenServer

  def start_link(_args) do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_args) do
    {:ok, connection} = AMQP.Connection.open(host: "queue")
    {:ok, channel} = AMQP.Channel.open(connection)

    AMQP.Queue.declare(channel, "logs")

    {:ok, %{channel: channel}}
  end

  def handle_cast({:get_logs, id}, state) do
    read_logs(id)
    {:noreply, state}
  end

  def handle_cast({:publish_logs, response}, state) do
    logs = response
      |> String.trim
      |> String.split("\n")
      |> Enum.map(&(String.slice(&1, 8..-1)))
      |> Enum.join("\n")
    push_logs_to_queue(logs, "test")
    {:noreply, state}
  end

  def get_log_url id do
    "#{Doxir.Application.containers_url}/#{id}/logs?stdout=true&stderr=true"
  end

  def read_logs(id) do
    %HTTPotion.AsyncResponse{id: async_id} =
      HTTPotion.get!(get_log_url(id), [stream_to: self()])
    collect_response(async_id, <<>>)
  end

  def push_logs_to_queue(logs, username) do
    IO.puts "got logs: #{logs}"
    {:ok, connection} = AMQP.Connection.open(host: "queue")
    {:ok, channel} = AMQP.Channel.open(connection)
    log_response = Poison.encode!(%{username: username, log: logs})
    AMQP.Basic.publish(channel, "", "logs", log_response)
  end

  def collect_response(id, data) do
    receive do
      %HTTPotion.AsyncHeaders{id: ^id, headers: _} ->
        collect_response(id, data)
      %HTTPotion.AsyncChunk{id: ^id, chunk: chunk} ->
        collect_response(id, data <> chunk)
      %HTTPotion.AsyncEnd{id: ^id} ->
        GenServer.cast(self(), {:publish_logs, data})
    end
  end
end