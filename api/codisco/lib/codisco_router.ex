defmodule Codisco.Router do
  use Plug.Router
  use Plug.Debugger
  require Logger

  plug Plug.Parsers, parsers: [:json],
                     pass:  ["text/*"],
                     json_decoder: Poison

  plug CORSPlug
  plug(Plug.Logger, log: :debug)

  plug(:match)
  plug(:dispatch)

  get "/" do
    send_resp(conn, 200, "hello, world")
  end

  post "/login" do
    %{"username" => username, "password" => password} = conn.body_params
    user = Codisco.User |> Codisco.Repo.get_by(username: username, password: password)
    case user do
      nil ->
        send_resp(conn, 401, "Unauthorized")
      _ ->
        send_resp(conn, 200, "Ok")
    end
    IO.inspect user
  end

  post "/user/create" do
    %{"username" => username, "password" => password} = conn.body_params
    user = %Codisco.User{username: username, password: password}
    resp = Codisco.Repo.insert(user)
    case resp do
      {:ok, _} ->
        send_resp(conn, 201, "Created")
      _ ->
        send_resp(conn, 400, "Invalid")
    end
  end

  get "/*path" do
    send_resp(conn, 404, "Not found")
  end
end
