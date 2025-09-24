defmodule Teleflex.Request do
  alias Teleflex.IPnet


  def internet? do
    url = Application.fetch_env!(:teleflex, :urls)[:internet_check]
    mother = self()

    spawn fn -> 
      case Req.head(url) do
        {:error, _} -> send mother, :error 
        {:ok, _} -> send mother, :ok
      end
    end

    receive do 
      :ok -> true
      :error -> false
    after 
      2_500 -> false
    end
  end


  @spec get_ipv4!() :: IPnet.ip4()
  def get_ipv4!() do
    url = Application.fetch_env!(:teleflex, :urls)[:ip_fetch]

    Req.get!(url).body
    |> IPnet.to_ip!()
  end

  @spec get_ipv6!() :: IPnet.ip6() | IPnet.ip4()
  def get_ipv6!() do
    url = Application.fetch_env!(:teleflex, :urls)[:ip_fetch]

    Req.get!(url, inet6: true).body
    |> IPnet.to_ip!()
  end
end
