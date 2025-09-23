defmodule Teleflex.Driver.P2P do 
  alias Teleflex.Driver
  alias Teleflex.IPnet
  @behaviour Driver 

  @spec init(ipnet :: IPnet.t()) :: Driver.feedback()
  def init(%IPnet{} = ipnet) do
    {_from, dest} = IPnet.get_addr(ipnet)

    # :net_kernel.start()
  end

  @spec send(ipnet :: IPnet.t(), msg :: term()) :: Driver.feedback()
  def send(%IPnet{} = ipnet, msg) do 
  

  end
end
