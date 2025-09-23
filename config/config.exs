import Config

config :teleflex,
  path: "~/.teleflex" |> Path.expand(),
  persist_time: 30,
  default_port: 12_000,
  range_port: 64

config :teleflex, :urls,
  internet_check: "https://www.google.com",
  ip_fetch: "https://ident.me"
