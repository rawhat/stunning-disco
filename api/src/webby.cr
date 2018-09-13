require "kemal"
require "login"

get "/" do
  "Hello, world!"
end

post "/login" do |env|
  user = User.from_json env.request.body.not_nil!
  {username: user.username, password: user.password}.to_json
end

Kemal.run
