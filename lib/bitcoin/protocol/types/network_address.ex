defmodule Bitcoin.Protocol.Types.NetworkAddress do

  defstruct time: 0, # (uint32) the Time (version >= 31402). Not present in version message.
            services: <<0, 0, 0, 0, 0, 0, 0, 0>>, # (uint64_t) bitfield of features to be enabled for this connection. See Version Message.
            address: {0, 0, 0, 0}, # decoded address tuple, 4 elemnt for IPv4, 8 element for IPv6 (see :inet)
            port: 8333 # (uint16_t) port number, network byte order

  @type t :: %Bitcoin.Protocol.Types.NetworkAddress{
    time: non_neg_integer,
    services: binary,
    address: tuple,
    port: non_neg_integer
  }

  def parse(<<time :: unsigned-native-integer-size(32),
              services :: bitstring-size(64),
              address :: bytes-size(16),
              port :: unsigned-big-integer-size(16)>>) do
    %Bitcoin.Protocol.Types.NetworkAddress{
      time: time,
      services: services,
      address: address |> addr_to_inet,
      port: port
    }
  end

  def parse_stream(<<time :: unsigned-native-integer-size(32),
                     services :: bitstring-size(64),
                     address :: bytes-size(16),
                     port :: unsigned-big-integer-size(16),
                     remaining_stream :: binary>>) do
    [%Bitcoin.Protocol.Types.NetworkAddress{
      time: time,
      services: services,
      address: address |> addr_to_inet,
      port: port
    }, remaining_stream]
  end

  def parse_version(<<services :: bitstring-size(64),
              address :: bytes-size(16),
              port :: unsigned-big-integer-size(16)>>) do
      %Bitcoin.Protocol.Types.NetworkAddress{
        services: services,
        address: address |> addr_to_inet,
        port: port
      }
    end

  def parse_version_stream(<<services :: bitstring-size(64),
              address :: bytes-size(16),
              port :: unsigned-big-integer-size(16),
              remaining_stream :: binary>>) do
    [%Bitcoin.Protocol.Types.NetworkAddress{
      services: services,
      address: address |> addr_to_inet,
      port: port
    }, remaining_stream]
  end

  # Binary representation as it is used in the Addr message
  def serialize(%Bitcoin.Protocol.Types.NetworkAddress{} = s) do
    <<
      s.time :: unsigned-native-integer-size(32),
      s.services :: bitstring-size(64),
      (s.address |> inet_to_addr) :: bytes-size(16),
      s.port :: unsigned-big-integer-size(16)
    >>
  end

  # Binary representation as it is used in the Version message
  def serialize_version(%Bitcoin.Protocol.Types.NetworkAddress{} = s) do
    <<
      s.services :: bitstring-size(64),
      (s.address |> inet_to_addr) :: bytes-size(16),
      s.port :: unsigned-big-integer-size(16)
    >>
  end

  # Convert address bytes to erlang :inet ip adress, IPv4
  def addr_to_inet(<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xFF, 0xFF, b1, b2, b3, b4>>), do: {b1, b2, b3, b4}
  def addr_to_inet(<<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, b1, b2, b3, b4>>), do: {b1, b2, b3, b4}
  def addr_to_inet(<< ipv6 :: binary-size(16) >>), do: {0,0,0,0} #TODO IPv6

  # Convert erlang inet ip adress to address byptes IPv4 (TODO IPv6)
  def inet_to_addr({b1, b2, b3, b4}), do: <<0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0xFF, 0xFF, b1, b2, b3, b4>> 

end
