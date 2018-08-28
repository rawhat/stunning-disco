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
    HTTPoison.get! "#{@images_url}/create?fromImage=node:latest"
    HTTPoison.get! "#{@images_url}/create?fromImage=python:latest"
    # TODO: not working.  404?
    #HTTPoison.get! "#{@images_url}/create?repo=frolvlad/alpine-gcc"
  end

  def init_containers do
    Doxir.post_json "#{@base_url}/images/create", Poison.encode!(%{"fromImage" => "node:latest"})
  end

  def list_containers do
    %HTTPoison.Response{body: body} = HTTPoison.get! "#{@containers_url}/json"
    Poison.decode body
  end

  def exec_node(script) do
    Poison.encode!(%{"Image" => "node:latest", "Cmd" => Doxir.get_node_exec(script)})
      |> Doxir.exec_in_container
  end

  def exec_python(script) do
    Poison.encode!(%{"Image" => "python:latest", "Cmd" => Doxir.get_python_exec(script)})
      |> Doxir.exec_in_container
  end

  def exec_c(script) do
    Poison.encode!(%{"Image" => "frolvlad/alpine-gcc:latest", "Cmd" => Doxir.get_c_exec(script)})
      |> Doxir.exec_in_container
  end

  def exec_in_container(create) do
    %HTTPoison.Response{body: body} = Doxir.post_json "#{@containers_url}/create", create
    id = Poison.decode!(body)
      |> Map.get("Id")
    Doxir.post_json "#{@containers_url}/#{id}/start"
    :timer.sleep(1000)
    %HTTPoison.AsyncResponse{id: async_id} =
      HTTPoison.get!(Doxir.get_log_url(id), %{}, stream_to: self())
    {:ok, %{body: response}} = Doxir.collect_response(async_id, self(), <<>>)
    response
      |> String.trim
      |> String.split("\n")
      |> Enum.map(&(String.slice(&1, 8..-1)))
      |> Enum.join("\n")
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
    HTTPoison.post! url, body, [{:"Content-Type", "application/json"}]
  end

  def get url do
    HTTPoison.get! url
  end

  def collect_response(id, par, data) do
    receive do
      %HTTPoison.AsyncStatus{id: ^id, code: 200} ->
        collect_response(id, par, data)
      %HTTPoison.AsyncHeaders{id: ^id, headers: _} ->
        collect_response(id, par, data)
      %HTTPoison.AsyncChunk{id: ^id, chunk: chunk} ->
        collect_response(id, par, data <> chunk)
      %HTTPoison.AsyncEnd{id: ^id} ->
        send par, {:ok, %{status_code: 200, body: data}}
    end
  end
end
