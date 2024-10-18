defmodule BinStructTest.VariantOfTests.OptionalFieldsTests.OptionalTail.NonePresentTest do

  use ExUnit.Case

  defmodule StructWithOptionalTail do

    use BinStruct

    field :required, :uint8
    field :optional_1, :uint8, optional: true
    field :optional_2, :uint8, optional: true

  end

  test "optional tail fields works when not present" do

    struct =
      StructWithOptionalTail.new(
        required: 0,
        optional_1: nil,
        optional_2: nil
      )

    dump = StructWithOptionalTail.dump_binary(struct)

    { :ok, parsed_struct } = StructWithOptionalTail.parse_exact(dump)

    values = StructWithOptionalTail.decode(parsed_struct)

    %{
      required: 0,
      optional_1: nil,
      optional_2: nil
    } = values

  end

end

