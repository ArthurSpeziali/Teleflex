defmodule Teleflex.Driver do
  alias Teleflex.IPnet
  alias Teleflex.Ajuster
  @mod Ajuster.driver()

  @type feedback() :: :ok | {:error, reason :: String.t()}
  @type response() :: {:ok, __MODULE__.t()} | {:error, String.t()}

  @callback start(ipnet :: IPnet.t()) :: feedback()
  @callback connect(my :: IPnet.t(), its :: IPnet.t()) :: response()
  @callback send_to(driver :: __MODULE__.t(), msg :: term()) :: feedback()
  @callback ping(driver :: __MODULE__.t()) :: feedback()
  @callback receive_from(driver :: __MODULE__.t(), timeout :: pos_integer() | :infinity) :: response()
  @callback receive_all(driver :: __MODULE__.t()) :: list()

  @typedoc "Driver struct"
  @type t :: 
          %__MODULE__{
            my: IPnet.t(),
            its: IPnet.t()
          }

  @enforce_keys [:my, :its]
  defstruct my: %IPnet{}, its: %IPnet{}


  @spec start(ipnet :: IPnet.t()) :: feedback()
  def start(%IPnet{} = ipnet) do 
    @mod.start(ipnet)
  end

  @spec connect(my :: IPnet.t(), its :: IPnet.t()) :: response()
  def connect(%IPnet{} = my, %IPnet{} = its) do 
    @mod.connect(my, its)
  end

  @spec send_to(driver :: __MODULE__.t(), msg :: term()) :: feedback()
  def send_to(%__MODULE__{} = driver, msg) do
    @mod.send_to(driver, msg)
  end

  @spec ping(driver :: __MODULE__.t()) :: feedback()
  def ping(%__MODULE__{} = driver) do 
    @mod.ping(driver)
  end

  @spec receive_from(driver :: __MODULE__.t(), timeout :: pos_integer() | :infinity) :: response()
  def receive_from(%__MODULE__{} = driver, timeout \\ 5_000) do 
    @mod.receive_from(driver, timeout)
  end

  @spec receive_all(driver :: __MODULE__.t()) :: list()
  def receive_all(%__MODULE__{} = driver) do 
    @mod.receive_all(driver)
  end
end
