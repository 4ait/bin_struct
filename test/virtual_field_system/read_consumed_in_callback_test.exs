defmodule BinStructTest.VirtualFieldSystem.ReadConsumedInCallbackTest do

  use ExUnit.Case

  defmodule StructWithVirtualFields do

    use BinStruct

    register_callback &read_enum/1,
                      number: %{ type: :field, type_conversion: :unmanaged }

    register_callback &read_bool_flag/1,
                      open_or_close_enum: :field

    virtual :open_or_close_enum, {
      :enum,
      %{
        type: :uint8,
        values: [
          { 0x00, :closed },
          { 0x01, :open },
        ]
      }
    }, read_by: &read_enum/1

    virtual :open_or_close_flag, :unspecified, read_by: &read_bool_flag/1

    field :number, :uint8

    defp read_enum(number), do: number

    defp read_bool_flag(open_or_close_enum) do

      IO.inspect(open_or_close_enum)

      nil

    end

  end

  test "struct with virtual write works" do

    struct = StructWithVirtualFields.new(number: 1)

    dump = StructWithVirtualFields.dump_binary(struct)

    { :ok, parsed_struct } = StructWithVirtualFields.parse_exact(dump)

    values = StructWithVirtualFields.decode(parsed_struct)

    %{
      open_or_close_enum: :open
    } = values

  end

end

