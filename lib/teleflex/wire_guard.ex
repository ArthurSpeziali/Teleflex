defmodule Teleflex.WireGuard do
  import Wireguardex.DeviceConfigBuilder
  import Wireguardex.PeerConfigBuilder, except: [public_key: 2]
  import Wireguardex, only: [set_device: 2]

  @on_load :init

  @path Application.compile_env(:teleflex, :path)
  @interface "wg0"
  @fwmark 0xFF55
  @port 51820

  def init() do
    File.mkdir_p!(@path |> Path.join("keys/"))

    private_path = @path |> Path.join("keys/wireguard_private")
    public_path = @path |> Path.join("keys/wireguard_public")

    wg_private = Wireguardex.generate_private_key()

    if !File.exists?(private_path) do
      File.write!(
        private_path,
        wg_private
      )
    end

    if !File.exists?(public_path) do
      {:ok, wg_public} = Wireguardex.get_public_key(wg_private)

      File.write!(
        public_path,
        wg_public
      )
    end

    :ok
  end

  def get_keys() do
    {
      @path |> Path.join("keys/wireguard_private") |> File.read!(),
      @path |> Path.join("keys/wireguard_public") |> File.read!()
    }
  end

  def start_dev() do
    {private, public} = get_keys()

    device_config()
    |> private_key(private)
    |> public_key(public)
    |> listen_port(@port)
    |> fwmark(@fwmark)
    |> set_device(@interface)
  end

  def add_peer(public, ip) do
    persist_time = Application.get_env(:teleflex, :persist_time)
    ip_endpoint = ip <> ":" <> to_string(@port)

    peer =
      peer_config()
      |> Wireguardex.PeerConfigBuilder.public_key(public)
      |> preshared_key(Wireguardex.generate_preshared_key())
      |> endpoint(ip_endpoint)
      |> persistent_keepalive_interval(persist_time)
      |> allowed_ips(["255.0.0.0/24", "127.0.0.0/16"])

    Wireguardex.add_peer(@interface, peer)
  end

  def remove_peer(public) do
    Wireguardex.remove_peer(@interface, public)
  end
end
