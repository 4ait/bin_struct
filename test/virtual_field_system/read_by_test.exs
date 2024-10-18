defmodule BinStructTest.VirtualFieldSystem.ReadByTest do

  use ExUnit.Case

  defmodule StructWithVirtualFields do

    import BinStructTest.Support.UtfEncoder, only: [ from_utf16_le_terminated: 1 ]

    use BinStruct

    register_callback &read_client_address_utf8/1, client_address: :field

    virtual :client_address_utf8, :binary, read_by: &read_client_address_utf8/1

    field :client_address, :binary

    defp read_client_address_utf8(client_address), do: from_utf16_le_terminated(client_address)


  end

  test "struct with virtual write works" do

    import BinStructTest.Support.UtfEncoder, only: [ to_utf16_le_terminated: 1 ]

    client_address_utf8 = "123"

    struct = StructWithVirtualFields.new(client_address: to_utf16_le_terminated(client_address_utf8))

    dump = StructWithVirtualFields.dump_binary(struct)

    { :ok, parsed_struct } = StructWithVirtualFields.parse_exact(dump)

    values = StructWithVirtualFields.decode(parsed_struct)

    %{
      client_address_utf8: ^client_address_utf8,
    } = values

  end

end

