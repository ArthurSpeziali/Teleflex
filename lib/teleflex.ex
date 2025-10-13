defmodule Teleflex do
  alias Teleflex.Driver
  alias Teleflex.IPnet

  @spec init() :: Driver.feedback()
  def init() do
    :ets.new(:teleflex, 
      [:named_table, :set, :public]
    )

    ipnet = IPnet.my()
    :ets.insert(:teleflex, {:ipnet, ipnet})

    Driver.start(ipnet)
  end

  @spec connect(ip :: String.t()) :: Driver.response()
  def connect(ip) do 
    {_key, my} = :ets.lookup(:teleflex, :ipnet) |> List.first()

    its = IPnet.new(ip)
    Driver.connect(my, its)
  end
end
