defmodule Doxir.ScriptRunner do

  @exec_bin ["/bin/sh", "-c"]
  @images_url "#{Doxir.Application.base_url}/images"

  def start do
    pull_images()
    :timer.sleep(10000)

    {:ok, connection} = AMQP.Connection.open(host: "queue")
    {:ok, channel} = AMQP.Channel.open(connection)

    AMQP.Queue.declare(channel, "commands")

    AMQP.Basic.consume(channel, "commands", nil, no_ack: true)
    wait_for_messages()
  end

  def exec_script(language, script, username) do
    IO.puts "got cast"
    case language do
      "js" ->
        exec_node(script, username)
      "py" ->
        exec_python(script, username)
      "c" ->
        exec_c(script, username)
    end
  end

  def pull_images do
    HTTPotion.get! "#{@images_url}/create?fromImage=node:latest"
    HTTPotion.get! "#{@images_url}/create?fromImage=python:latest"
    # TODO: not working.  404?
    #HTTPotion.get! "#{@images_url}/create?repo=frolvlad/alpine-gcc"
  end

  def init_containers do
    post_json "#{Doxir.Application.base_url}/images/create", Poison.encode!(%{"fromImage" => "node:latest"})
  end

  def list_containers do
    %HTTPotion.Response{body: body} = HTTPotion.get! "#{Doxir.Application.containers_url}/json"
    Poison.decode body
  end

  def exec_node(script, username \\ "test") do
    Poison.encode!(%{"Image" => "node:latest", "Cmd" => get_node_exec(script)})
      |> exec_in_container
  end

  def exec_python(script, username \\ "test") do
    Poison.encode!(%{"Image" => "python:latest", "Cmd" => get_python_exec(script)})
      |> exec_in_container
  end

  def exec_c(script, username \\ "test") do
    Poison.encode!(%{"Image" => "frolvlad/alpine-gcc:latest", "Cmd" => get_c_exec(script)})
      |> exec_in_container
  end

  def exec_in_container(create) do
    %HTTPotion.Response{body: body} = post_json "#{Doxir.Application.containers_url}/create", create
    id = Poison.decode!(body)
      |> Map.get("Id")
    post_json "#{Doxir.Application.containers_url}/#{id}/start"
    :timer.sleep(1000)
    IO.puts "going to write logs to other gen server"
    GenServer.cast(Doxir.LogReader, {:get_logs, id})
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
      |> parse_script
      |> get_exec("runner.js", "node")
  end

  def get_python_exec script do
    script
      |> parse_script
      |> get_exec("runner.py", "python3")
  end

  def get_c_exec script do
    @exec_bin ++
      ["/bin/echo \"#{parse_script(script)}\" > runner.c && gcc -o main runner.c && ./main"]
  end

  def get_exec(script, file, executable) do
    @exec_bin ++ ["/bin/echo \"#{script}\" > #{file} && #{executable} #{file}"]
  end

  def get_log_url id do
    "#{Doxir.Application.containers_url}/#{id}/logs?stdout=true&stderr=true"
  end

  def post_json url, msg \\ nil do
    body = if msg != nil, do: msg, else: Poison.encode!(%{})
    HTTPotion.post! url, [body: body, headers: ["Content-Type": "application/json"]]
  end

  def get url do
    HTTPotion.get! url
  end

  def wait_for_messages() do
    receive do
      {:basic_deliver, payload, _meta} ->
        IO.puts " [x] Received #{payload}"
        %{"language" => language, "script" => script, "username" => username} =
          Poison.decode!(payload)
        exec_script(language, script, username)
        wait_for_messages()
    end
  end
end
