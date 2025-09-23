defmodule Teleflex.Driver do
  alias Teleflex.IPnet
  alias Teleflex.Configer
  @mod Configer.driver()

  @type feedback() :: :ok | {:error, reason :: String.t()}
  @type response() :: {:ok, term()} | {:error, reason :: String.t()}

  @callback init(ipnet :: IPnet.t()) :: feedback()
  @callback send_to(ipnet :: IPnet.t(), msg :: term()) :: feedback()
  @callback ping(ipnet :: IPnet.t()) :: feedback()
  @callback receive_from(ipnet :: IPnet.t(), timeout :: pos_integer() | :infinity) :: response()


  @spec init(ipnet :: IPnet.t()) :: feedback()
  def init(%IPnet{} = ipnet) do 
    @mod.init(ipnet)
  end

  @spec send_to(ipnet :: IPnet.t(), msg :: term()) :: feedback()
  def send_to(%IPnet{} = ipnet, msg) do
    @mod.send_to(ipnet, msg)
  end

  @spec ping(ipnet :: IPnet.t()) :: feedback()
  def ping(%IPnet{} = ipnet) do 
    @mod.ping(ipnet)
  end

  @spec receive_from(ipnet :: IPnet.t(), timeout :: pos_integer() | :infinity) :: response()
  def receive_from(%IPnet{} = ipnet, timeout \\ 5_000) do 
    @mod.receive_from(ipnet, timeout)
  end
end
