defmodule Teleflex do
  alias Teleflex.Driver
  alias Teleflex.IPnet
  alias Teleflex.Contract

  @spec init() :: Driver.feedback()
  def init() do
    :ets.new(:teleflex, 
      [:named_table, :set, :public]
    )

    ipnet = IPnet.my()
    :ets.insert(:teleflex, {:ipnet, ipnet})

    Driver.start(ipnet)
  end

  @spec connect(dest :: String.t()) :: Driver.response()
  def connect(dest) do 
    {_key, my} = :ets.lookup(:teleflex, :ipnet) |> List.first()
    if my == [], do: throw("run 'init/0' before this function")

    its = IPnet.new(dest)

    case Driver.connect(my, its) do
      {:ok, driver} -> 
        :ets.insert(:teleflex, {:driver, driver}) 
        {:ok, driver}

      error -> error
    end
  catch 
    value -> {:error, value}
  end

  @spec send(msg :: String.t()) :: Contract.response()
  def send(msg) when is_binary(msg) do 
    {_key, driver} = :ets.lookup(:teleflex, :driver) |> List.first()
    if driver == [], do: throw("run 'connect/1' before this function")

    case Contract.new(msg, driver) do 
      {:ok, contract} -> 
        :ets.insert(:teleflex, {:contract, contract})
        {:ok, contract}

      error -> error
    end
  catch 
    value -> {:error, value}
  end
end
