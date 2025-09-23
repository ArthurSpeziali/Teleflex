defmodule Teleflex.Application do
  # See https://hexdocs.pm/elixir/Application.html
  # for more information on OTP Applications
  @moduledoc false

  use Application

  @impl true
  def start(_type, _args) do
    Teleflex.WireGuard.init()
    Teleflex.Configer.init()

    Application.put_env(:kernel, :inet_dist_listen_min, 9000)
    Application.put_env(:kernel, :inet_dist_listen_max, 9000)

    children = [
      # Starts a worker by calling: Teleflex.Worker.start_link(arg)
      # {Teleflex.Worker, arg}
    ]

    # See https://hexdocs.pm/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Teleflex.Supervisor]
    Supervisor.start_link(children, opts)
  end
end
