defmodule BinStructTest.VirtualFieldSystem.WriteByTest do

  use ExUnit.Case

  defmodule StructWithVirtualFields do

    import BinStructTest.Support.UtfEncoder, only: [ to_utf16_le_terminated: 1 ]

    use BinStruct

    register_callback &write_unicode_string/1,
                      arguments: [
                        utf8_binary: :argument
                      ],
                      returns: [
                        :length,
                        :utf16_le_terminated_binary
                      ]

    virtual :utf8_binary, :unmanaged, write_by: &write_unicode_string/1

    field :length, :uint16_be
    field :utf16_le_terminated_binary, :binary

    defp write_unicode_string(utf8_string) do

      utf16_le_terminated_binary = to_utf16_le_terminated(utf8_string)

      %{
        length: byte_size(utf16_le_terminated_binary),
        utf16_le_terminated_binary: utf16_le_terminated_binary
      }

    end

  end

  test "struct with virtual write_by works" do

    struct = StructWithVirtualFields.new(utf8_binary: "123")

    dump = StructWithVirtualFields.dump_binary(struct)

    { :ok, parsed_struct } = StructWithVirtualFields.parse_exact(dump)

    values = StructWithVirtualFields.decode(parsed_struct)

    %{
      length: 8,
      utf16_le_terminated_binary: <<49, 0, 50, 0, 51, 0, 0, 0>>
    } = values

  end

end

