defmodule Doxir.CodeController do
  use DoxirWeb, :controller

  def index(conn, _params) do
    conn |> send_resp(200, "hello, world")
  end

  def submit(conn, _params) do
    conn |> send_resp(200, "Ok")
  end
end
