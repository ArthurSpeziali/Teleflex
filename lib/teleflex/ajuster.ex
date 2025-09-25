defmodule Teleflex.Ajuster do
  @path Application.compile_env!(:teleflex, :path) |> Path.join("config.json")

  def init() do
    unless File.exists?(@path) do
      Path.dirname(@path)
      |> File.mkdir_p!()

      write_config()
    end

    :ok
  end

  defp default_config() do 
    %{
      "driver" => "p2p",
      "default_port" => 12_000,
      "range_port" => 64
    }
  end

  defp write_config() do
    File.write!(
      @path,
      default_config()
      |> Jason.encode!(pretty: true)
    )
  end

  defp write_config(field) do
    config = File.read!(@path)
           |> Jason.decode!()

    new = %{config | field => default_config()[field]} 
          |> Jason.encode!(pretty: true)

    File.write!(
      @path, 
      new
    )
  end

  def driver() do 
    driver =
      File.read!(@path)
      |> Jason.decode!()
      |> Map.get("driver")

    case driver do
      "p2p" -> 
        Teleflex.Driver.P2P

      "tor" -> 
        Teleflex.Driver.Tor
      _ -> 
        write_config("driver")
        default(:driver)
    end
  end

  def ports() do
    config = File.read!(@path)
             |> Jason.decode!()

    port = Map.get(config, "default_port")
    range = Map.get(config, "range_port")

    if !port || !range do
      write_config("default_port")
      write_config("range_port")
      default(:port)
    else 
      port..port+(range - 1)//1
    end
  end


  defp default(:driver) do 
    Teleflex.Driver.P2P
  end
  defp default(:port) do 
    12_000..12_063//1
  end
end
