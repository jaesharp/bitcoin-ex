defmodule Bitcoin.Protocol.Messages.Verack do

  @moduledoc """
    The verack message is sent in reply to version.
    This message consists of only a message header with the command string "verack".

    https://en.bitcoin.it/wiki/Protocol_specification#verack
  """

  defstruct []

  def parse(_data) do
    %__MODULE__{}
  end

  def serialize(_), do: <<>>

end
