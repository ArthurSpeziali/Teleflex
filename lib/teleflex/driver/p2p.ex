defmodule Teleflex.Driver.P2P do 
  alias Teleflex.Driver
  alias Teleflex.IPnet
  @behaviour Driver 
  
  @node_name Application.compile_env(:teleflex, :node_opts)[:name]
  @node_cookie Application.compile_env(:teleflex, :node_opts)[:cookie]
  @node_proc Application.compile_env(:teleflex, :node_opts)[:proc]


  @spec init(ipnet :: IPnet.t()) :: Driver.feedback()
  def init(%IPnet{} = my_ipnet) do
    dest = IPnet.get_addr(my_ipnet)
    node = :"#{@node_name}@#{dest}"

    case Node.start(node) do
      {:ok, _pid} -> 
        Node.set_cookie(@node_cookie) 
        :ok

      {:error, _} -> 
        {:error, "node start error"}
    end
  end

  @spec send_to(ipnet :: IPnet.t(), msg :: term()) :: Driver.feedback()
  def send_to(%IPnet{} = its_ipnet, msg) do 
    dest = IPnet.get_addr(its_ipnet)
    node = :"#{@node_name}@#{dest}"

    if Node.ping(node) == :pong do
      send {@node_proc, node}, msg
      :ok
    else
      {:error, "node unreachable"}
    end
  end

  @spec ping(ipnet :: IPnet.t()) :: Driver.feedback()
  def ping(%IPnet{} = its_ipnet) do
    dest = IPnet.get_addr(its_ipnet)
    node = :"#{@node_name}@#{dest}"

    if Node.ping(node) == :pong do
      :ok
    else
      {:error, "node unreachable"}
    end
  end

  @spec receive_from(ipnet :: IPnet.t(), timeout :: pos_integer() | :infinity) :: Driver.response()
  def receive_from(%IPnet{} = its_ipnet, timeout \\ 5_000) do
    dest = IPnet.get_addr(its_ipnet)

    receive do 
      {^dest, msg} -> {:ok, msg}
    after 
      timeout -> {:error, "timeout error"}
    end
  end

end
