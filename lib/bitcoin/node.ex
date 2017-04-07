defmodule Bitcoin.Node do
  use GenServer

  require Lager

  @default_config %{
    listen_ip: '0.0.0.0',
    listen_port: 8333,
    max_connections: 8,
    user_agent: "/Bitcoin-Ex:0.0.0/",
    data_directory: Path.expand("~/.bitcoin-ex"),
    services: <<1, 0, 0, 0, 0, 0, 0, 0>> # TODO probably doesn't belong to config
  }

  @protocol_version 70002


  # Interface

  def start_link, do: GenServer.start(__MODULE__, nil, name: __MODULE__)
  def version_fields,  do: GenServer.call(__MODULE__, :version_fields)
  def config,  do: GenServer.call(__MODULE__, :config)
  def nonce,  do: GenServer.call(__MODULE__, :nonce)
  def height, do: 1

  # Implementation

  def init(_) do
    self() |> send(:initialize)
    {:ok, %{}}
  end

  def handle_info(:initialize, state) do
    Lager.info "Node initialization"

    config = case Application.fetch_env(:bitcoin, :node) do
      :error -> @default_config
      {:ok, config} -> 
        @default_config |> Map.merge(config |> Enum.into(%{}))
    end

    File.mkdir_p(config.data_directory)

    state = state|> Map.merge(%{
      nonce: Bitcoin.Util.nonce64(),
      config: config
    })

    {:noreply, state}
  end

  def handle_call(:config, _from, state), do: {:reply, state.config, state}
  def handle_call(:nonce, _from, state), do: {:reply, state.nonce, state}

  def handle_call(:version_fields, _from, state) do
    fields = %{
      height: height(),
      nonce: state.nonce,
      relay: true,
      services: <<1, 0, 0, 0, 0, 0, 0, 0>>,
      timestamp: timestamp(),
      version: @protocol_version,
      user_agent: state.config[:user_agent],
    }
    {:reply, fields, state}
  end


  def timestamp do
    {megas, s, _milis} = :os.timestamp
    round(1.0e6*megas + s)
  end
end
