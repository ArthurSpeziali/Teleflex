defmodule Teleflex.Server.Receiver do 
  use GenServer
  alias Teleflex.Contract
  @node_proc Application.compile_env(:teleflex, :node_opts)[:proc]

  # GenServer functions 
  def start_link(state \\ []) do 
    if Process.whereis(@node_proc) do 
      {:error, "server already started"}
    else
      GenServer.start_link(__MODULE__, state, name: __MODULE__) 
    end
  end
  
  def init(state) do 
    spawn_monitor(&receiver/0)

    {:ok, state}
  end 

  def handle_info({:DOWN, _ref, :process, _pid, :normal}, state) do 
    {:stop, :normal, state}
  end


  # API functions 
  def receiver() do 
    receive do 
      %Contract{} = contract -> 
        IO.inspect(contract)
        receiver()

      :stop -> 
        :ok
    end
  end

end
