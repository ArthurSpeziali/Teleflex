import Config

config :teleflex,
  path: "~/.teleflex" |> Path.expand(),
  persist_time: 30
