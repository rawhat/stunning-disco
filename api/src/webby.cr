require "kemal"

get "/" do
  "Hello, world!"
end

get "/other" do
  "Other route, bruv"
end

Kemal.run
