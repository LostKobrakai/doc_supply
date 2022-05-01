import Config

# We don't run a server during test. If one is required,
# you can enable the server option below.
config :doc_supply, DocSupplyWeb.Endpoint,
  http: [ip: {127, 0, 0, 1}, port: 4002],
  secret_key_base: "SVerHlV5bjJpPZyhG/7O0JhtRthCgbZ6m4+Znl8hcbWjwyCD+OznU2SZWaX5nMGx",
  server: false

# In test we don't send emails.
config :doc_supply, DocSupply.Mailer,
  adapter: Swoosh.Adapters.Test

# Print only warnings and errors during test
config :logger, level: :warn

# Initialize plugs at runtime for faster test compilation
config :phoenix, :plug_init_mode, :runtime
