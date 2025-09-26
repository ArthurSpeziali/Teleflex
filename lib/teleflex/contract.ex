defmodule Teleflex.Contract do
  alias Teleflex.Ajuster
  alias Teleflex.Validate

  @type hash_byte() :: <<_::512>>
  @type response() :: {:ok, __MODULE__.t()} | {:error, String.t()}

  @typedoc "Contract type"
  @type t() :: %__MODULE__{
    name: String.t(),
    id: hash_byte(),
    size: pos_integer(),
    hash: binary(),
    max_size: pos_integer(),
    block_list: list(),
    compromise: :waiting | :accept | :ignored,
    blob: binary()
  }

  @enforce_keys [:name, :id, :max_size]
  defstruct name: "", id: <<0::64*8>>, size: 0, hash: <<0::64*8>>, max_size: 0, block_list: [], compromise: :waiting, blob: <<>>


  defimpl Inspect, for: Teleflex.Contract do
    import Inspect.Algebra 

    def inspect(contract, _opts) do
      concat ["#Contract<#{contract.name}>"]
    end
  end



  ## Funcs
  @spec new(text :: String.t()) :: response()
  def new(text) do
    if !Validate.str?(text) do
      throw("invalid string")
    end

    {:ok, 
      %__MODULE__{
        name: gen_name(),
        id: gen_id(),
        size: byte_size(text),
        hash: get_hash(text),
        max_size: Ajuster.max_size(),
        block_list: Ajuster.block_list(),
        compromise: :waiting, 
        blob: text
      }
    }

  catch 
    value -> 
      {:error, value}
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
end
