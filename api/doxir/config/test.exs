use Mix.Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :doxir, DoxirWeb.Endpoint,
  http: [port: 4001],
  server: false

# Print only warnings and errors during test
config :logger, level: :warn

# Configure your database
config :doxir, Doxir.Repo,
  username: "postgres",
  password: "postgres",
  database: "doxir_test",
  hostname: "localhost",
  pool: Ecto.Adapters.SQL.Sandbox
