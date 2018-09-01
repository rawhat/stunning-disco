defmodule Doxir do
  @moduledoc """
  Documentation for Doxir.
  """

  @doc """
  Hello world.

  ## Examples

      iex> Doxir.hello()
      :world

  """

  @base_url "http://10.0.2.15:2375"
  @containers_url "#{@base_url}/containers"
  @exec_bin ["/bin/sh", "-c"]
  @images_url "#{@base_url}/images"

  def pull_images do
    HTTPotion.get! "#{@images_url}/create?fromImage=node:latest"
    HTTPotion.get! "#{@images_url}/create?fromImage=python:latest"
    # TODO: not working.  404?
    #HTTPotion.get! "#{@images_url}/create?repo=frolvlad/alpine-gcc"
  end

  def init_containers do
    Doxir.post_json "#{@base_url}/images/create", Poison.encode!(%{"fromImage" => "node:latest"})
  end

  def list_containers do
    %HTTPotion.Response{body: body} = HTTPotion.get! "#{@containers_url}/json"
    Poison.decode body
  end

  def exec_node(script, username \\ "test") do
    Poison.encode!(%{"Image" => "node:latest", "Cmd" => Doxir.get_node_exec(script)})
      |> Doxir.exec_in_container
  end

  def exec_python(script, username \\ "test") do
    Poison.encode!(%{"Image" => "python:latest", "Cmd" => Doxir.get_python_exec(script)})
      |> Doxir.exec_in_container
  end

  def exec_c(script, username \\ "test") do
    Poison.encode!(%{"Image" => "frolvlad/alpine-gcc:latest", "Cmd" => Doxir.get_c_exec(script)})
      |> Doxir.exec_in_container
  end

  def exec_in_container(create) do
    %HTTPotion.Response{body: body} = Doxir.post_json "#{@containers_url}/create", create
    id = Poison.decode!(body)
      |> Map.get("Id")
    Doxir.post_json "#{@containers_url}/#{id}/start"
    :timer.sleep(1000)
    %HTTPotion.AsyncResponse{id: async_id} =
      HTTPotion.get!(Doxir.get_log_url(id), [stream_to: self()])
    {:ok, %{body: response}} = Doxir.collect_response(async_id, self(), <<>>)
    logs = response
      |> String.trim
      |> String.split("\n")
      |> Enum.map(&(String.slice(&1, 8..-1)))
      |> Enum.join("\n")
    IO.inspect logs
    Doxir.push_logs_to_queue(logs, "test")
  end

  def push_logs_to_queue(logs, username) do
    IO.puts "done!"
    {:ok, connection} = AMQP.Connection.open(host: "queue")
    {:ok, channel} = AMQP.Channel.open(connection)
    log_response = Poison.encode!(%{username: username, log: logs})
    AMQP.Basic.publish(channel, "", "logs", log_response)
  end

  def parse_script script do
    ~s(#{script}) |> String.replace(~s("), "\\\"")
  end

  def get_node_exec script do
    script
      |> Doxir.parse_script
      |> Doxir.get_exec("runner.js", "node")
  end

  def get_python_exec script do
    script
      |> Doxir.parse_script
      |> Doxir.get_exec("runner.py", "python3")
  end

  def get_c_exec script do
    @exec_bin ++
      ["/bin/echo \"#{Doxir.parse_script(script)}\" > runner.c && gcc -o main runner.c && ./main"]
  end

  def get_exec(script, file, executable) do
    @exec_bin ++ ["/bin/echo \"#{script}\" > #{file} && #{executable} #{file}"]
  end

  def get_log_url id do
    "#{@containers_url}/#{id}/logs?stdout=true&stderr=true"
  end

  def post_json url, msg \\ nil do
    body = if msg != nil, do: msg, else: Poison.encode!(%{})
    HTTPotion.post! url, [body: body, headers: ["Content-Type": "application/json"]]
  end

  def get url do
    HTTPotion.get! url
  end

  def collect_response(id, par, data) do
    receive do
      %HTTPotion.AsyncHeaders{id: ^id, headers: _} ->
        collect_response(id, par, data)
      %HTTPotion.AsyncChunk{id: ^id, chunk: chunk} ->
        collect_response(id, par, data <> chunk)
      %HTTPotion.AsyncEnd{id: ^id} ->
        send par, {:ok, %{status_code: 200, body: data}}
    end
  end

  def init_queue do
    {:ok, connection} = AMQP.Connection.open(host: "queue")
    {:ok, channel} = AMQP.Channel.open(connection)
    AMQP.Queue.declare(channel, "commands")
    AMQP.Queue.declare(channel, "logs")
    AMQP.Basic.consume(channel, "commands", nil, no_ack: true)
    IO.puts "now waiting for messages..."
    Doxir.wait_for_messages
  end

  def wait_for_messages() do
    receive do
      {:basic_deliver, payload, _meta} ->
        IO.puts " [x] Received #{payload}"
        %{"language" => language, "script" => script, "username" => username} =
          Poison.decode!(payload)
        case language do
          "js" ->
            Doxir.exec_node(script, username)
          "py" ->
            Doxir.exec_python(script, username)
          "c" ->
            Doxir.exec_c(script, username)
        end
        wait_for_messages()
    end
  end
end

Doxir.init_queue
