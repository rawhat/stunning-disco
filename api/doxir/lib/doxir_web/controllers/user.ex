defmodule DoxirWeb.UserController do
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

  def create(conn, params) do
    %{"username" => username, "password" => password} = params
    user = Doxir.User.changeset(%Doxir.User{}, %{username: username, password: password})
    resp = Doxir.Repo.insert(user)
    case resp do
      {:ok, _} ->
        send_resp(conn, 201, "Created")
      _ ->
        send_resp(conn, 409, "Invalid")
    end
  end
end
