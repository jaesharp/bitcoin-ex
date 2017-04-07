defmodule Bitcoin.Protocol.Message.Header do

  @known_network_identifiers %{
    main: <<0xF9, 0xBE, 0xB4, 0xD9>>,
    testnet: <<0xFA, 0xBF, 0xB5, 0xDA>>,
    testnet3: <<0x0B, 0x11, 0x09, 0x07>>,
    namecoin: <<0xF9, 0xBE, 0xB4, 0xFE>>
  } 

  defstruct network_identifier: 0,
            command: <<>>,
            payload_size_bytes: 0,
            checksum: 0

  @type t :: %__MODULE__{
    network_identifier: non_neg_integer,
    command: String.t,
    payload_size_bytes: non_neg_integer,
    checksum: non_neg_integer # sha256(sha256(payload)) first four bytes
  }

  def parse(<<network_identifier :: unsigned-little-integer-size(32),
                    command :: bytes-size(12),
                    payload_size_bytes :: unsigned-little-integer-size(32),
                    checksum :: unsigned-little-integer-size(32)
                  >>) do

    %__MODULE__{
      network_identifier: network_identifier,
      command: command |> String.trim_trailing(<<0>>),
      payload_size_bytes: payload_size_bytes,
      checksum: checksum
    }
  end

  def serialize(%__MODULE__{} = s) do
    command = s.command |> String.pad_trailing(12, <<0>>)
    << 
      s.network_identifier :: unsigned-little-integer-size(32),
      command :: bytes-size(12),
      s.payload_size_bytes :: unsigned-little-integer-size(32),
      s.checksum :: unsigned-little-integer-size(32)
    >>
  end

  def checksum(payload) do
    << result :: unsigned-little-integer-size(32), _ :: binary >> = :crypto.hash(:sha256, :crypto.hash(:sha256, payload))
    result
  end

end

