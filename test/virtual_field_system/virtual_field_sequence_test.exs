defmodule BinStructTest.VirtualFieldSystem.StructWithSequenceTest do

  use ExUnit.Case

  defmodule StructWithSequenceOfVirtualFields do

    use BinStruct

    alias BinStruct.TypeConversion.TypeConversionBinary

    register_callback &read_v1_from_a/1,
                      a: :field

    register_callback &read_v2_from_v1/1,
                      v1: :field

    register_callback &read_v3_from_v2/1,
                      v2: :field

    register_callback &length_from_v3_managed/1,
                      v3: :field

    register_callback &length_from_v3_binary/1,
                      v3: %{ type: :field, type_conversion: TypeConversionBinary }

    virtual :v1, :uint8, read_by: &read_v1_from_a/1
    virtual :v2, :uint8, read_by: &read_v2_from_v1/1
    virtual :v3, :uint8, read_by: &read_v3_from_v2/1

    field :a, :uint8
    field :b, :binary, length_by: &length_from_v3_managed/1
    field :c, :binary, length_by: &length_from_v3_binary/1

    defp read_v1_from_a(a), do: a
    defp read_v2_from_v1(v1), do: v1
    defp read_v3_from_v2(v2), do: v2

    defp length_from_v3_managed(v3), do: v3

    defp length_from_v3_binary(v3_binary) do
      <<integer::8-integer-big-unsigned>> = v3_binary
      integer
    end

  end

  test "struct with virtual field sequence works" do


    struct = StructWithSequenceOfVirtualFields.new(a: 1, b: <<1>>, c: <<2>>)

    dump = StructWithSequenceOfVirtualFields.dump_binary(struct)

    { :ok, parsed_struct } = StructWithSequenceOfVirtualFields.parse_exact(dump)


    values = StructWithSequenceOfVirtualFields.decode(parsed_struct)

    %{
      a: 1,
      b: <<1>>,
      c: <<2>>,
      v1: 1,
      v2: 1,
      v3: 1,
    } = values

  end

end

