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
      "range_port" => 64,
      "max_size" => 1 * 1_024 ** 2, ## 1MB
      "block_list" => []
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

    new = 
      if config[field] do 
        %{config | field => default_config()[field]} 
        |> Jason.encode!(pretty: true)
      else 
        Map.put(config, field, default_config()[field])
        |> Jason.encode!(pretty: true)
      end

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

    if is_integer(port) && is_integer(range) do
      port..port+(range - 1)//1
    else 
      write_config("default_port")
      write_config("range_port")
      default(:port)
    end
  end

  def max_size() do
    max_size = File.read!(@path)
               |> Jason.decode!()
               |> Map.get("max_size")

    if is_integer(max_size) do
      max_size
    else 
      write_config("max_size")
      default(:max_size)
    end
  end

  def block_list() do 
    block_list = File.read!(@path)
               |> Jason.decode!()
               |> Map.get("block_list")

    if is_list(block_list) do 
      block_list
    else 
      write_config("block_list")
      default(:block_list)
    end
  end


  defp default(:driver) do 
    Teleflex.Driver.P2P
  end
  defp default(:port) do 
    12_000..12_063//1
  end
  defp default(:max_size) do 
    1 * 1024 ** 2
  end
  defp default(:block_list) do
    []
  end
end
