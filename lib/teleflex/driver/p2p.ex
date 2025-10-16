defmodule Teleflex.Driver.P2P do 
  alias Teleflex.Driver
  alias Teleflex.IPnet
  @behaviour Driver 
  
  @node_name Application.compile_env(:teleflex, :node_opts)[:name]
  @node_cookie Application.compile_env(:teleflex, :node_opts)[:cookie]
  @node_proc Application.compile_env(:teleflex, :node_opts)[:proc]


  @spec start(ipnet :: IPnet.t()) :: Driver.feedback()
  def start(%IPnet{} = my_ipnet) do
    dest = IPnet.get_addr(my_ipnet)
    node = :"#{@node_name}@#{dest}"

    # Process.register(self(), @node_proc)

    case Node.start(node) do
      {:ok, _pid} -> 
        Node.set_cookie(@node_cookie) 
        :ok

      {:error, _} -> 
        {:error, "node start error"}
    end
  end

  @spec connect(my :: IPnet.t(), its :: IPnet.t()) :: Driver.response()
  def connect(%IPnet{} = my, %IPnet{} = its) do 
    dest = IPnet.get_addr(my)
    node = :"#{@node_name}@#{dest}"
    res = Node.connect(node)

    if res && res != :ignored do
      {:ok,
        %Driver{
          my: my,
          its: its
        }
      }
    else 
      {:error, "node conn error"}
    end
  end

  @spec send_to(driver :: Driver.t(), msg :: term()) :: Driver.feedback()
  def send_to(%Driver{} = driver, msg) do 
    dest = IPnet.get_addr(driver.its)
    node = :"#{@node_name}@#{dest}"

    if Node.ping(node) == :pong do
      self_dest = IPnet.get_addr(driver.my)

      send {@node_proc, node}, {self_dest, msg}
      :ok
    else
      {:error, "node unreachable"}
    end
  end

  @spec ping(driver :: Driver.t()) :: Driver.feedback()
  def ping(%Driver{} = driver) do
    dest = IPnet.get_addr(driver.its)
    node = :"#{@node_name}@#{dest}"

    if Node.ping(node) == :pong do
      :ok
    else
      {:error, "node unreachable"}
    end
  end

  @spec receive_from(driver :: Driver.t(), timeout :: pos_integer() | :infinity) :: {:error, String.t()} | String.t()
  def receive_from(%Driver{} = driver, timeout \\ 5_000) do
    dest = IPnet.get_addr(driver.its)
    messages = loop_receive_from(dest, timeout)

    if messages == [] do
      {:error, "timeout"}
    else 
      messages
    end
  end

  defp loop_receive_from(dest, timeout) do 
    receive do 
      {^dest, msg} -> 
        [msg | loop_receive_from(dest, 50)]
    after 
      timeout -> []
    end
  end

  @spec receive_all(driver :: Driver.t()) :: list()
  def receive_all(%Driver{} = _driver) do 
    loop_receive_all()
  end

  defp loop_receive_all() do
    receive do
      {from, msg} -> 
        [{from, msg} | loop_receive_all()]

    after 
      50 -> 
        []
    end
  end
end
