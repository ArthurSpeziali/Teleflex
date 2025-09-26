defmodule Teleflex.Validate do
  @type feedback :: :ok | {:error, String.t()}

  def str?(bin) do 
    cond do 
      !is_binary(bin) -> false
      !String.printable?(bin) -> false
      true -> true
    end
  end

end
