defmodule Bitcoin.Protocol.Message do

  @moduledoc """
    https://en.bitcoin.it/wiki/Protocol_documentation#Message_structure
  """

  alias Bitcoin.Protocol.Messages
  alias Bitcoin.Protocol.Message.Payload
  alias Bitcoin.Protocol.Message.Header

  defimpl String.Chars, for: Bitcoin.Protocol.Message do

    @spec to_string(Message) :: String.t
    def to_string(item) do
      """
      Bitcoin Protocol Message
      ===

      Message Header
      ---
      #{item.header}

      Payload
      ---
      #{item.payload.to_string()}

      """
    end

  end

  defstruct header: Header,
            payload: Payload

  @type t :: %{
    header: Header.t,
    payload: Payload.t
  }

  @commands %{
    "addr"       => Messages.Addr,
    "alert"      => Messages.Alert,
    "block"      => Messages.Block,
    "getaddr"    => Messages.GetAddr,
    "getblocks"  => Messages.GetBlocks,
    "getdata"    => Messages.GetData,
    "getheaders" => Messages.GetHeaders,
    "headers"    => Messages.Headers,
    "inv"        => Messages.Inv,
    "notfound"   => Messages.NotFound,
    "ping"       => Messages.Ping,
    "pong"       => Messages.Pong,
    "reject"     => Messages.Reject,
    "tx"         => Messages.Tx,
    "verack"     => Messages.Verack,
    "version"    => Messages.Version
  }

  @message_types @commands |> Map.values()
  @command_names @commands |> Map.keys()


  @doc """
    Reads and deserialises bitcoin message in serialised format and returns the parsed result
  """
  @spec parse(bitstring) :: Bitcoin.Protocol.Message.t
  def parse(message) do

    <<raw_header :: bytes-size(24), # fixed size header
      payload :: binary
    >> = message

    header  = Header.parse(raw_header)

    %__MODULE__{
      header: header,
      payload: Payload.parse(header.command, payload)
    }

  end

  def parse_stream(message) do

    <<
      raw_header :: bytes-size(24),
      data :: binary
    >> = message

    header  = Header.parse(raw_header)

    if byte_size(data) < header.payload_size_bytes do
      [nil, message]
    else
      size = header.payload_size_bytes
      <<
        payload :: binary-size(size),
        remaining :: binary
      >> = data

      message = %__MODULE__{
        header: header,
        payload: Payload.parse(header.command, payload)
      }

      [message, remaining]
    end

  end

  @doc """
    Returns message type associated with given command
  """
  def message_type(command), do: @commands[command]

  @doc """
    Returns command associated with given message type
  """
  def command_name(message_type) when message_type in @message_types do
    @commands
      |> Enum.find(fn {_k,v} -> v == message_type end)
      |> elem(0)
  end

  @doc """
    List of supported commands
  """
  def command_names, do: @command_names

  @doc """
    Serialize message type struct into a full binary message that is ready to be send over the network
  """
  def serialize(%{__struct__: message_type} = struct) when message_type in @message_types do

    << network_identifier :: unsigned-little-integer-size(32) >> = <<0xF9, 0xBE, 0xB4, 0xD9>># TODO read from config (e.g. magic[Node.network()]

    payload = message_type.serialize(struct)

    header = %Header{
      network_identifier: network_identifier,
      command: message_type |> command_name,
      payload_size_bytes: byte_size(payload),
      checksum: Header.checksum(payload)
    }

    Header.serialize(header) <> payload
  end
end
