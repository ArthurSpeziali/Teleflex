defmodule Teleflex.IPnet do
  alias Teleflex.Request
  alias Teleflex.Configer

  @type ip4 :: {byte, byte, byte, byte}
  @type ip6 :: {byte, byte, byte, byte, byte, byte, byte, byte}
  @type ip :: ip4() | ip6()
  @type dns :: String.t()
  @type dest :: ip() | dns()

  @typedoc "IP Address (dns and port) structure"
  @type t :: 
          %__MODULE__{
            ipv4: ip4(),
            ipv6: ip6(),
            dns: dns(),
            port: port()
          }


  defstruct ipv4: {0, 0, 0, 0}, ipv6: {0, 0, 0, 0, 0, 0, 0, 0}, dns: ".", port: Configer.ports().first

  defimpl Inspect, for: Teleflex.IPnet do
    import Inspect.Algebra 
    alias Teleflex.IPnet

    def inspect(ipnet, _opts) do
      concat ["#IPnet<#{IPnet.get_addr(ipnet)}:#{ipnet.port}>"]
    end
  end

  defprotocol Conv do
    def to_str(str)
    def to_str!(ip)
    def to_ip(ip)
    def to_ip!(ip)

    def which_ip(ip)
    def which_ip!(ip)
  end

  ## IMPLs
  
  defimpl Conv, for: Tuple do 
    alias Teleflex.IPnet
    defguard is_ip(ip) when is_tuple(ip) and (tuple_size(ip) == 4 or tuple_size(ip) == 8)


    @spec to_str(ip :: IPnet.ip()) :: String.t() | {:error, String.t()}
    def to_str(ip) when is_ip(ip) do
      res =
        :inet.ntoa(ip) 

      case res do
        {:error, _} -> 
          {:error, "invalid IP format"}

        _ -> 
          res |> to_string()
      end
    end

    @spec to_str!(ip :: IPnet.ip()) :: String.t() | no_return()
    def to_str!(ip) when is_ip(ip) do
      case to_str(ip) do
        {:error, msg} -> raise msg
        str -> str
      end
    end 

    @spec to_ip(ip :: IPnet.ip()) :: IPnet.ip() | {:error, String.t()}
    def to_ip(ip) when is_ip(ip), do: ip

    @spec to_ip!(ip :: IPnet.ip()) :: IPnet.ip() | no_return()
    def to_ip!(ip) when is_ip(ip), do: ip

    @spec which_ip(ip :: IPnet.ip()) :: :ipv4 | :ipv6 | :error
    def which_ip(ip) when is_ip(ip) do
      case tuple_size(ip) do
        4 -> :ipv4
        8 -> :ipv6
        _ -> :error
      end
    end

    @spec which_ip!(ip :: IPnet.ip()) :: :ipv4 | :ipv6 | no_return()
    def which_ip!(ip) when is_ip(ip) do
      case which_ip(ip) do
        :error -> raise "invalid IP format"
        res -> res
      end
    end
  end

  defimpl Conv, for: BitString do
    alias Teleflex.IPnet

    @spec to_str(str :: String.t()) :: String.t() | {:error, String.t()}
    def to_str(str), do: str

    @spec to_str!(str :: String.t()) :: String.t() | no_return()
    def to_str!(str), do: str

    @spec to_ip(str :: String.t()) :: IPnet.ip() | {:error, String.t()}
    def to_ip(str) do 
      ipv = which_ip(str)

      if ipv == :ipv4 do
        case String.to_charlist(str) |> :inet.parse_ipv4_address() do
          {:ok, ip} -> ip
          {:error, _} -> {:error, "invalid IPv4 format"}
        end
      else
        case String.to_charlist(str) |> :inet.parse_ipv6_address() do
          {:ok, ip} -> ip
          {:error, _} -> {:error, "invalid IPv6 format"}
        end
      end
    end

    @spec to_ip!(str :: String.t()) :: IPnet.ip() | no_return()
    def to_ip!(str) do
      case to_ip(str) do
        {:error, msg} -> raise msg
        ip -> ip
      end
    end

    @spec which_ip(str :: String.t()) :: :ipv4 | :ipv6 | :error   
    def which_ip(str) do
        cond do
          String.contains?(str, ":") -> :ipv6
          String.contains?(str, ".") -> :ipv4
          true -> :error
        end
    end

    @spec which_ip!(str :: String.t()) :: :ipv4 | :ipv6 | no_return()
    def which_ip!(str) do
      case which_ip(str) do
        :error -> raise "invalid IP format"
        res -> res
      end
    end
  end

  
  ## Aliases for Conv IMPLs 
  @spec to_ip!(data :: any()) :: ip() | no_return()
  def to_ip!(data), do: Conv.to_ip!(data)

  @spec to_str!(data :: any()) :: String.t() | no_return()
  def to_str!(data), do: Conv.to_str!(data)

  @spec to_ip(data :: any()) :: ip() | {:error, String.t()}
  def to_ip(data), do: Conv.to_ip(data)

  @spec to_str(data :: any()) :: String.t() | {:error, String.t()}
  def to_str(data), do: Conv.to_str(data)

  @spec which_ip!(data :: any()) :: :ipv4 | :ipv6 | no_return()
  def which_ip!(data), do: Conv.which_ip!(data)

  @spec which_ip(data :: any()) :: :ipv4 | :ipv6 | :error 
  def which_ip(data), do: Conv.which_ip(data)



  ## Outer funcs
  @spec default(atom()) :: term() 
  def default(:port) do 
    Configer.ports().first
  end
  def default(:ip6) do
    {0, 0, 0, 0, 0, 0, 0, 0}
  end 
  def default(:ip4) do
    {0, 0, 0, 0}
  end
  def default(:dns) do
    "."
  end

  @spec my() :: __MODULE__.t()
  def my() do
    ipv4 = Request.get_ipv4!()
    ipv6 = Request.get_ipv6!()

    if ipv6 == ipv4 do
      new(ipv4)
    else
      new(ipv6, ipv4: ipv4)
    end
  end

  @spec define_dest(dest :: dest()) :: :ipv4 | :ipv6 | :dns | :error
  def define_dest(dest) do
    case dest do
      dns when is_binary(dns) -> :dns 
      ipv4 when is_tuple(ipv4) and (tuple_size(ipv4) == 4) -> :ipv4
      ipv6 when is_tuple(ipv6) and (tuple_size(ipv6) == 8) -> :ipv6
      _ -> :error
    end
  end


  ## Funcs for IPnet
  @spec new(dest :: dest(), opts :: keyword()) :: __MODULE__.t()
  def new(dest, opts \\ []) do
    ipv4 = Keyword.get(opts, :ipv4, default(:ip4))
    ipv6 = Keyword.get(opts, :ipv6, default(:ip6))
    dns = Keyword.get(opts, :dns, default(:dns))
    port = Keyword.get(opts, :port, default(:port))

    %__MODULE__{
      ipv4: ipv4,
      ipv6: ipv6,
      dns: dns,
      port: port
    } |> Map.update!(
      define_dest(dest),
      fn _ -> dest end
    )
  end

  @spec get_addr(ipnet :: __MODULE__.t()) :: String.t()
  def get_addr(%__MODULE__{} = ipnet) do
    cond do
      ipnet.dns != default(:dns) -> ipnet.dns
      ipnet.ipv6 != default(:ip6) -> "[#{ipnet.ipv6 |> to_str!()}]"
      true -> ipnet.ipv4 |> to_str!()
    end
  end
end
