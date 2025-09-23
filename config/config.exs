import Config

config :teleflex,
  path: "~/.teleflex" |> Path.expand(),
  persist_time: 30

config :teleflex, :urls,
  internet_check: "https://www.google.com",
  ip_fetch: "https://ident.me"
