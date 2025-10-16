defmodule Teleflex.IPnet do
  alias Teleflex.Request
  alias Teleflex.Ajuster
  alias Teleflex.Validate

  @type ipv4 :: {byte, byte, byte, byte}
  @type ipv6 :: {byte, byte, byte, byte, byte, byte, byte, byte}
  @type ip :: ipv4() | ipv6()
  @type dns :: String.t()
  @type dest :: ip() | dns()

  @typedoc "IP Address (dns and port) structure"
  @type t :: 
          %__MODULE__{
            ipv4: ipv4(),
            ipv6: ipv6(),
            dns: dns(),
            port: port()
          }


  defstruct ipv4: {0, 0, 0, 0}, ipv6: {0, 0, 0, 0, 0, 0, 0, 0}, dns: ".", port: Ajuster.ports().first

  defimpl Inspect, for: Teleflex.IPnet do
    import Inspect.Algebra 
    alias Teleflex.IPnet

    def inspect(ipnet, _opts) do
      concat ["#IPnet<#{IPnet.get_addr(ipnet)}:#{ipnet.port}>"]
    end
  end

  defprotocol Conv do
    def to_str(ip)
    def to_str!(ip)
    def to_ip(ip)
    def to_ip!(ip)

    def which_ip(ip)
    def which_ip!(ip)
    def define_dest(ip)

    def valid_ip?(ip)
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

    @spec define_dest(ip :: IPnet.ip()) :: :ipv4 | :ipv6 | :error
    def define_dest(ip) when is_ip(ip) do
      which_ip(ip)
    end

    @spec valid_ip?(ip :: IPnet.ip()) :: boolean() 
    def valid_ip?(ip) when is_ip(ip) do 
      case which_ip(ip) do 
        :ipv4 -> 
          {b1, b2, b3, b4} = ip 

          if !(b1 in 1..254//1 && b2 in 0..255//1 && b4 in 1..255//1), do: throw("invalid ip range")
          if b1 == 255 && b2 == 255 && b3 == 255 && b4 == 255, do: throw("broadcast is invalid")

          ## IPs Reserveds
          if b1 == 10, do: throw("reserved ip")
          if b1 == 172 && b2 in 16..31//1, do: throw("reserved ip")
          if b1 == 192, do: throw("reserved ip")
          if b1 == 127, do: throw("reserved ip")
          if b1 == 169 && b2 == 254, do: throw("reserved ip") 
          if b1 in 224..239//1, do: throw("reserved ip") 
          if b1 == 0, do: throw("reserved ip") 
          if b1 == 255, do: throw("reserved ip")
          if b1 == 100 && b2 == 64, do: throw("reserved ip")
          if b1 == 198 && b2 == 18, do: throw("reserved ip")
          if b1 == 198 && b2 == 51 && b3 == 100, do: throw("reserved ip")
          if b1 == 203 && b2 == 0 && b3 == 113, do: throw("reserved ip")

        
        :ipv6 -> 
          list_bytes = Tuple.to_list(ip)

          all? =
            Enum.all?(list_bytes, fn byte ->
              byte in 0..0xffff
            end)  

          if !all?, do: throw("invalid ip range")  
          if Enum.sum(list_bytes) == 0, do: throw("null ip")  

          ## IPs reserved
          if {0, 0, 0, 0, 0, 0, 0, 1} == ip, do: throw("reserved ip")  
          if List.first(list_bytes) == 0xfe80, do: throw("reserved ip")
          if List.first(list_bytes) == 0xff00, do: throw("reserved ip")
          if List.first(list_bytes) == 0xfc00, do: throw("reserved ip")
          if Enum.at(list_bytes, 2) == 0xffff, do: throw("reserved ip")
          if Enum.at(list_bytes, 0) == 0x64 && Enum.at(list_bytes, 1) == 0xff9b, do: throw("reserved ip")
          if Enum.at(list_bytes, 0) == 0x2001 && Enum.at(list_bytes, 1) == 0xdb8, do: throw("reserved ip")
          if List.first(list_bytes) in [0x100, 0x2000, 0x3000], do: throw("reserved ip")
      end

      true
    catch 
      _value -> false
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

    @spec define_dest(str :: binary()) :: :ipv4 | :ipv6 | :dns | :error
    def define_dest(str) do
      case which_ip(str) do
        :ipv4 ->
          String.replace(str, ".", "")
          |> Integer.parse()
          |> case do 
            {_int, ""} -> :ipv4 
            _any -> :dns
          end

        res ->
          res
      end
    end

    @spec valid_ip?(str :: binary()) :: boolean()
    def valid_ip?(str) do
      case to_ip(str) do 
        {:error, _} -> false
        ip -> IPnet.valid_ip?(ip)
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

  @spec define_dest(data :: any()) :: :ipv4 | :ipv6 | :dns | :error
  def define_dest(data), do: Conv.define_dest(data)

  @spec valid_ip?(data :: any()) :: boolean()
  def valid_ip?(data), do: Conv.valid_ip?(data)


  ## Outer funcs
  @spec default(atom()) :: term() 
  def default(:port) do 
    Ajuster.ports().first
  end
  def default(:ipv6) do
    {0, 0, 0, 0, 0, 0, 0, 0}
  end 
  def default(:ipv4) do
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


  ## Funcs for IPnet
  @spec new(dest :: dest(), opts :: keyword()) :: __MODULE__.t()
  def new(dest, opts \\ []) do
    type = define_dest(dest)
    dest = 
      if type != :dns do 
        to_ip!(dest)
      end

    ipv4 = Keyword.get(opts, :ipv4, default(:ipv4))
           |> to_ip()

    ipv6 = Keyword.get(opts, :ipv6, default(:ipv6))
           |> to_ip()

    dns = Keyword.get(opts, :dns, default(:dns))
    port = Keyword.get(opts, :port, default(:port))

    %__MODULE__{
      ipv4: ipv4,
      ipv6: ipv6,
      dns: dns,
      port: port
    } |> Map.update!(
      type,
      fn _ -> dest end
    )
  end

  @spec get_addr(ipnet :: __MODULE__.t()) :: String.t()
  def get_addr(%__MODULE__{} = ipnet) do
    cond do
      ipnet.dns != default(:dns) -> ipnet.dns
      ipnet.ipv6 != default(:ipv6) -> "[#{ipnet.ipv6 |> to_str!()}]"
      true -> ipnet.ipv4 |> to_str!()
    end
  end

  @spec valid?(ipnet :: __MODULE__.t()) :: boolean() 
  def valid?(%__MODULE__{} = ipnet) do 
    if [:ipv4, :ipv6, :dns, :port] -- Map.keys(ipnet) != [], do: throw(false)

    if !is_tuple(ipnet.ipv4) || !is_tuple(ipnet.ipv6) || !Validate.str?(ipnet.dns) || !is_integer(ipnet.port) do 
      throw(false)
    end

    if ipnet.port < 1000, do: throw(false)
    if !String.contains?(ipnet.dns, "."), do: throw(false)
    if tuple_size(ipnet.ipv4) != 4 && tuple_size(ipnet.ipv6) != 8, do: throw(false)

    if (ipnet.ipv4 == default(:ipv4)) && (ipnet.ipv6 == default(:ipv6)) do 
      throw(false)
    end 

    if ipnet.ipv4 != default(:ipv4) && !valid_ip?(ipnet.ipv4), do: throw(false) 
    if ipnet.ipv6 == default(:ipv6) do 
      true
    else 
      valid_ip?(ipnet.ipv6)  
    end
  catch 
    any -> any
  end
end
