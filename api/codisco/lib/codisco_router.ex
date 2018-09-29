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
    case conn.body_params do
      %{"username" => username, "password" => password} ->
        user = Codisco.User |> Codisco.Repo.get_by(username: username, password: password)
        case user do
          nil ->
            send_resp(conn, 401, "Unauthorized")
          _ ->
            send_resp(conn, 200, "Ok")
        end
      _ ->
        send_resp(conn, 401, "Unauthorized")
    end
  end

  post "/user/create" do
    %{"username" => username, "password" => password} = conn.body_params
    user = Codisco.User.changeset(%Codisco.User{}, %{username: username, password: password})
    resp = Codisco.Repo.insert(user)
    case resp do
      {:ok, _} ->
        send_resp(conn, 201, "Created")
      _ ->
        send_resp(conn, 409, "Invalid")
    end
  end

  post "/submit" do
    %{"language" => language, "script" => script, "username" => username} = conn.body_params
    # send this to the message queue
    IO.inspect conn.body_params
    resp = GenServer.call(Codisco.ScriptExecutor, {:exec_script, language, script, username})
    IO.inspect resp
    send_resp(conn, 200, "Ok")
  end

  get "/*path" do
    send_resp(conn, 404, "Not found")
  end
end
