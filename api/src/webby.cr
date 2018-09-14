require "amqp"
require "db"
require "kemal"
require "pg"

require "./login"
#require "./queue"
require "./websocket"

db_url = "postgres://postgres@db:5432"
db = DB.open(db_url)

ws_users = {} of String => HTTP::WebSocket

#queue_channels = QueueChannels.new

# CORS setup
before_all do |env|
  puts env.request
  env.response.headers.add("Access-Control-Allow-Origin", "*")
  env.response.headers.add("Access-Control-Allow-Methods", "GET, HEAD, POST, PUT")
  env.response.headers.add(
    "Access-Control-Allow-Headers",
    "Content-Type, Accept, Origin, Authorization"
  )
end

get "/" do
  "Hello, world!"
end

options "/login" do
end

post "/login" do |env|
  user = User.from_json env.request.body.not_nil!
  db.query(
    "select * from users where \
     username = $1 \
     and password = $2;
    ", [user.username, user.password]
  ) do |res|
    case res.column_count > 0
    when true
      {status: 200, message: "Ok"}.to_json
    else
      {status: 401, message: "Invalid"}.to_json
    end
  end
end

post "/user/create" do |env|
  user = User.from_json env.request.body.not_nil!
  res = db.exec(
    "insert into users values ($1, $2);",
    [user.username, user.password]
  )
  case res.rows_affected > 0
  when true
    {status: 200, message: "Ok"}.to_json
  when false
    {status: 403, message: "Unauthorized"}.to_json
  end
end

options "/submit" do
end

post "/submit" do |env|
  submission = Submission.from_json env.request.body.not_nil!
  AMQP::Connection.start(AMQP::Config.new("queue")) do |conn|
    conn.on_close do |code, msg|
      puts "CONNECTION CLOSED: #{code} - #{msg}"
    end
    channel = conn.channel
    exchange = channel.direct("doxir")
    #exchange = channel.default_exchange
    #queue = channel.queue("logs")
    #queue.bind(exchange, queue.name)
    msg = AMQP::Message.new(submission.to_json)
    puts "sending message to commands: #{msg.to_s}"
    exchange.publish(msg, "commands")
    {status: 200, message: "Ok"}
  end
end

ws "/coder" do |socket|
  socket.on_message do |message|
    ws_message = WebSocketMessage.from_json message
    puts ws_message
    case ws_message.action
    when Action::Register
      username = ws_message.message.as_h["username"].as_s
      ws_users[username] = socket
    end
  end

  socket.on_close do |_|
    ws_users.delete_if { |_, value| value == socket }
  end

  #if queue = queue_channels.queue
    #queue.subscribe do |msg|
      #puts "got msg: #{msg.to_s}"
    #end
  #end
  #AMQP::Connection.start(AMQP::Config.new("queue")) do |conn|
    #conn.on_close do |code, msg|
      #puts "CONNECTION CLOSED: #{code} - #{msg}"
    #end
    #channel = conn.channel
    #exchange = channel.direct("doxir")
    #queue = channel.queue("logs")
    #queue.bind(exchange, queue.name)
    #queue.subscribe do |msg|
      #puts "got msg: #{msg.to_s}"
    #end
  #end
end

AMQP::Connection.start(AMQP::Config.new("queue")) do |conn|
  conn.on_close do |code, msg|
    puts "CONNECTION CLOSED: #{code} - #{msg}"
  end
  channel = conn.channel
  exchange = channel.direct("doxir")
  queue = channel.queue("logs")
  #exchange.publish(AMQP::Message.new("test"), "logs")
  queue.subscribe do |msg|
    puts "got log message: #{msg.to_s}"
    log = LogResponse.from_json msg.to_s
    if ws_users[log.username]?
      ws_users[log.username].send log.log
    end
  end
end

Fiber.yield

Kemal.run
