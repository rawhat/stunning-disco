defmodule Doxir.UserController do
  use DoxirWeb, :controller

  def login(conn, params) do
    case params do
      %{"username" => username, "password" => password} ->
        user = Doxir.User
          |> Doxir.Repo.get_by(username: username, password: password)
        case user do
          nil ->
            conn
            |> send_resp(401, "Unauthorized")
          _ ->
            conn
            |> send_resp(200, "Ok")
        end
      _ ->
        conn
        |> send_resp(401, "Unauthorized")
    end
  end

  def create(conn, _params) do
    conn |> send_resp(200, "Ok")
  end
end
