defmodule Doxir.LogReader do

  use GenServer

  def start_link(_args) do
    GenServer.start_link __MODULE__, [], name: __MODULE__
  end

  def init(_args) do
    {:ok, connection} = AMQP.Connection.open(host: "queue")
    {:ok, channel} = AMQP.Channel.open(connection)

    AMQP.Exchange.declare(channel, "doxir", :direct)
    AMQP.Queue.declare(channel, "logs")
    AMQP.Queue.bind(channel, "logs", "doxir")

    {:ok, %{channel: channel}}
  end

  def handle_cast({:get_logs, id}, state) do
    read_logs(id)
    {:noreply, state}
  end

  def handle_cast({:publish_logs, logs}, state) do
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
    {:ok, connection} = AMQP.Connection.open(host: "queue")
    {:ok, channel} = AMQP.Channel.open(connection)
    log_response = Poison.encode!(%{username: username, log: logs})
    IO.puts "publishing #{log_response}"
    AMQP.Basic.publish(channel, "doxir", "logs", log_response)
  end

  def collect_response(id, data) do
    receive do
      %HTTPotion.AsyncHeaders{id: ^id, headers: _} ->
        collect_response(id, data)
      %HTTPotion.AsyncChunk{id: ^id, chunk: chunk} ->
        collect_response(id, data <> chunk)
      %HTTPotion.AsyncEnd{id: ^id} ->
        logs = data
          |> String.trim
          |> String.split("\n")
          |> Enum.map(&(String.slice(&1, 8..-1)))
          |> Enum.join("\n")
        if logs == "" do
          IO.puts "empty logs, retrying"
          :timer.sleep(1000)
          read_logs(id)
        else
          GenServer.cast(self(), {:publish_logs, logs})
        end
    end
  end
end
