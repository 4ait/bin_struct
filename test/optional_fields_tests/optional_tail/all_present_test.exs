defmodule BinStructTest.VariantOfTests.OptionalFieldsTests.OptionalTail.AllPresentTest do

  use ExUnit.Case

  defmodule StructWithOptionalTail do

    use BinStruct

    field :required, :uint8
    field :optional_1, :uint8, optional: true
    field :optional_2, :uint8, optional: true

  end

  test "optional tail fields works when present" do

    struct =
      StructWithOptionalTail.new(
        required: 0,
        optional_1: 1,
        optional_2: 2
      )

    dump = StructWithOptionalTail.dump_binary(struct)

    { :ok, parsed_struct } = StructWithOptionalTail.parse_exact(dump)

    values = StructWithOptionalTail.decode(parsed_struct)

    %{
      required: 0,
      optional_1: 1,
      optional_2: 2
    } = values

  end

end

