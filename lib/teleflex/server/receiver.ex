defmodule Teleflex.Server.Receiver do 
  alias Teleflex.Contract
  @node_proc Application.compile_env(:teleflex, :node_opts)[:proc]

  def start_link(_state \\ nil) do 
    if Process.whereis(@node_proc) do 
      {:error, "server already started"}
    else
      pid = spawn(&receiver/0)
      Process.register(pid, @node_proc)

      {:ok, pid}
    end
  end

  # Functions 
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
