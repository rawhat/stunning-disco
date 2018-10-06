defmodule DoxirWeb.Router do
  use DoxirWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/" do
    pipe_through :api

    #options "/", Doxir.CodeController, :options
    get "/", DoxirWeb.CodeController, :index
    #options "/login", Doxir.UserController, :options
    post "/login", DoxirWeb.UserController, :login
    #options "/user/create", Doxir.UserController, :options
    post "/user/create", DoxirWeb.UserController, :create
    #options "/submit", Doxir.CodeController, :options
    post "/submit", DoxirWeb.CodeController, :submit
  end
end
