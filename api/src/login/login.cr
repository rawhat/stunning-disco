require "json"


struct User
  JSON.mapping(
    username: String,
    password: String,
  )
end

struct Submission
  JSON.mapping(
    language: String,
    script: String,
    username: String,
  )
end

struct LogResponse
  JSON.mapping(
    username: String,
    log: String,
  )
end
