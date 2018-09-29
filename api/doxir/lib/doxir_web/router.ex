defmodule DoxirWeb.Router do
  use DoxirWeb, :router

  pipeline :api do
    plug :accepts, ["json"]
  end

  scope "/", DoxirWeb do
    pipe_through :api

    #options "/", Doxir.CodeController, :options
    get "/", Doxir.CodeController, :index
    #options "/login", Doxir.UserController, :options
    post "/login", Doxir.UserController, :login
    #options "/user/create", Doxir.UserController, :options
    post "/user/create", Doxir.UserController, :create
    #options "/submit", Doxir.CodeController, :options
    post "/submit", Doxir.CodeController, :submit
  end
end
