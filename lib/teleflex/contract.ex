defmodule Teleflex.Contract do
  alias Teleflex.Driver
  alias Teleflex.IPnet
  alias Teleflex.Ajuster
  alias Teleflex.Validate

  @type hash_byte() :: <<_::512>>
  @type response() :: {:ok, __MODULE__.t()} | {:error, String.t()}
  @type advice() :: __MODULE__.t() | {:error, String.t()}
  @type feedback() :: :ok | {:error, String.t()}

  @typedoc "Contract type"
  @type t() :: %__MODULE__{
    name: String.t(),
    id: hash_byte(),
    driver: Driver.t(),
    size: nil | pos_integer(),
    hash: nil | binary(),
    max_size: pos_integer(),
    block_list: list(),
    compromise: :waiting | :process | :accept | :ignored,
    blob: nil | binary()
  }

  @enforce_keys [:name, :id, :max_size, :driver]
  defstruct name: "", id: <<0::64*8>>, driver: %Driver{my: nil, its: nil}, size: 0, hash: <<0::64*8>>, max_size: 0, block_list: [], compromise: :waiting, blob: nil


  defimpl Inspect, for: Teleflex.Contract do
    import Inspect.Algebra 

    def inspect(contract, _opts) do
      concat ["#Contract<#{contract.name}>"]
    end
  end



  ## Funcs
  @spec new(driver :: Driver.t()) :: response()
  def new(%Driver{} = driver) do
    contract = 
      %__MODULE__{
        name: gen_name(),
        id: gen_id(),
        driver: driver,
        size: nil,
        hash: nil,
        max_size: Ajuster.max_size(),
        block_list: Ajuster.block_list(),
        compromise: :waiting, 
        blob: nil
      }

    if blocked?(driver) do
      {:ok, contract}
    else 
      {:error, "dest is blocked"}
    end
  end


  @spec gen_id() :: hash_byte()
  def gen_id() do
    base = (DateTime.utc_now() |> DateTime.to_unix()) * System.unique_integer()
           |> to_string()
           |> Base.encode16()

    :crypto.hash(:sha256, base)
    |> Base.encode16()
  end

  @spec gen_name() :: String.t()
  def gen_name() do
    DateTime.utc_now()
    |> DateTime.to_unix()
    |> to_string()
  end

  @spec get_hash(blob :: binary()) :: hash_byte()
  def get_hash(blob) do
    :crypto.hash(:sha256, blob)
  end


  ## Funcs for Driver
  @spec block(Driver.t()) :: feedback()
  def block(%Driver{its: ipnet}) do 
    block_list = Ajuster.block_list()
      
    dest = IPnet.get_addr(ipnet)
    new_block_list = [dest | block_list]
    
    if !(dest in block_list) do
      Ajuster.change("block_list", new_block_list)
    else 
      {:error, "dest alredy blocked"}
    end
  end

  @spec blocked?(Driver.t()) :: boolean()
  def blocked?(%Driver{its: ipnet}) do 
    block_list = Ajuster.block_list()

    dest = IPnet.get_addr(ipnet)
    !(dest in block_list)
  end

  @spec unblock(Driver.t()) :: feedback()
  def unblock(%Driver{its: ipnet}) do 
    block_list = Ajuster.block_list()

    dest = IPnet.get_addr(ipnet)
    new_block_list = block_list -- [dest]

    if dest in block_list do
      Ajuster.change("block_list", new_block_list)
    else 
      {:error, "dest is not blocked"}
    end
  end


  ## Funcs for contract 
  @spec put_content(__MODULE__.t(), text :: String.t()) :: response()
  def put_content(%__MODULE__{} = contract, text) do 
    if !Validate.str?(text) do 
      throw("invalid string")
    end

    size = byte_size(text)
    hash = get_hash(text)

    if size <= contract.max_size do 
      new = %{contract | 
        blob: text, 
        size: size, 
        hash: hash,
        compromise: :process
      }
      {:ok, new}
    else 
      {:error, "max size reached"}
    end

  catch 
    value -> 
      {:error, value}
  end
end
