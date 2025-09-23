defmodule Teleflex.Driver do
  alias Teleflex.IPnet
  @type feedback() :: :ok | {:error, reason :: String.t()}

  @callback init(ipnet :: IPnet.t()) :: feedback()
  @callback send(ipnet :: IPnet.t(), msg :: term()) :: feedback()
end
