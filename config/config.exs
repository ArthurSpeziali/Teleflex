import Config

config :teleflex,
  path: "~/.teleflex" |> Path.expand(),
  persist_time: 30,
  limit_max_size: 25 * 1024 ** 2  ## 25 Mb

config :teleflex, :urls,
  internet_check: "https://www.google.com",
  ip_fetch: "https://ident.me"

config :teleflex, :node_opts,
  name: :teleflex,
  proc: :messager,
  cookie: :fish
