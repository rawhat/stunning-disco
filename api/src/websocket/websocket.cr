require "json"


enum Action
  Register
end

struct WebSocketMessage
  JSON.mapping(
    action: Action,
    message: JSON::Any
  )
end

struct RegisterMessage
  JSON.mapping(
    username: String,
  )
end
