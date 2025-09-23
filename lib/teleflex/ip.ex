defmodule Teleflex.IPnet do

  @type ip4 :: {byte, byte, byte, byte}
  @type ip6 :: {byte, byte, byte, byte, byte, byte, byte, byte}
  @type ip :: ip4() | ip6()
  @type dns :: String.t()
  @type dest :: ip() | dns()
  @type tf_port :: 12000..12063

  @typedoc "IP Address (dns and port) structure"
  @type t :: 
          %__MODULE__{
            ipv4: ip4(),
            ipv6: ip6(),
            dns: dns(),
            port: tf_port()
          }


  @enforce_keys [:ipv4, :port]
  defstruct ipv4: {0, 0, 0, 0}, ipv6: {0, 0, 0, 0, 0, 0, 0, 0}, dns: "", port: 12000

  defimpl Inspect, for: Teleflex.IPnet do
    import Inspect.Algebra 

    def inspect(ipnet, _opts) do
      cond do
        ipnet.dns != "" -> 
          concat ["IPnet<#{ipnet.dns}:#{ipnet.port}>"]
        ipnet.ipv6 != {0, 0, 0, 0, 0, 0, 0, 0} -> 
          concat ["IPnet<[#{:inet.ntoa(ipnet.ipv6)}]:#{ipnet.port}>"]
        true -> 
          concat ["IPnet<#{:inet.ntoa(ipnet.ipv4)}:#{ipnet.port}>"]
      end
    end
  end


  ## Functions !!!

  @spec string_to_ip(str :: String.t()) :: ip() | {:error, String.t()}
  def string_to_ip(str) when is_binary(str) do
    ipv = 
      cond do
        String.contains?(str, ":") -> :ipv6
        String.contains?(str, ".") -> :ipv4
        true -> throw "invalid IP format"
      end

    if ipv == :ipv4 do
      case :inet.parse_ipv4_address(String.to_charlist(str)) do
        {:ok, ip} -> ip
        {:error, _} -> throw "invalid IPv4 format"
      end
    else
      case :inet.parse_ipv6_address(String.to_charlist(str)) do
        {:ok, ip} -> ip
        {:error, _} -> throw "invalid IPv6 format"
      end
    end
  catch
    msg ->
      {:error, msg}
  end

  @spec string_to_ip!(str :: String.t()) :: ip() | no_return()
  def string_to_ip!(str) when is_binary(str) do
    case string_to_ip(str) do
      {:error, msg} -> raise msg
      ip -> ip
    end
  end

  
  @spec ip_to_string(ip :: ip()) :: String.t() | {:error, String.t()}
  def ip_to_string(ip) when is_tuple(ip) do
    res =
      :inet.ntoa(ip) 

    case res do
      {:error, _} -> 
        {:error, "invalid IP format"}

      _ -> 
        res |> to_string()
    end
  end

  @spec ip_to_string!(ip :: ip()) :: String.t() | no_return()
  def ip_to_string!(ip) when is_tuple(ip) do
    case ip_to_string(ip) do
      {:error, msg} -> raise msg
      str -> str
    end
  end 
end
