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

  @spec connect(dest :: String.t()) :: Contract.response()
  def connect(dest) do 
    {_key, my} = :ets.lookup(:teleflex, :ipnet) |> List.first()
    if my == [], do: throw("run 'init/0' before this function")

    its = IPnet.new(dest)

    driver = Driver.connect(my, its) 
    case driver do 
      {:error, reason} -> throw(reason)
      _ -> :ok
    end

    {:ok, driver} = driver
    case Contract.new(driver) do 
      {:ok, contract} -> 
        :ets.insert(:teleflex, {:contract, contract})
        {:ok, contract}

      error -> error
    end

  catch 
    value -> {:error, value}
  end

  @spec send(msg :: String.t()) :: Contract.response()
  def send(msg) when is_binary(msg) do 
    {_key, contract} = :ets.lookup(:teleflex, :contract) |> List.first()
    if contract == [], do: throw("run 'connect/1' before this function")

    case Contract.put_content(contract, msg) do
      {:ok, contract} ->
        :ets.insert(:teleflex, {:contract, contract})
        Driver.send_to(
          contract.driver,
          contract.blob
        )

      error -> error
    end
  catch 
    value -> {:error, value}
  end

#   @spec receive(dest :: String.t()) :: any()
#   def receive(dest) do 
    
#   end
end
