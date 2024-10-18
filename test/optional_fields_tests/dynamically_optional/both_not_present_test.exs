defmodule BinStructTest.VariantOfTests.OptionalFieldsTests.DynamicallyOptional.BothNotPresentTest do

  use ExUnit.Case

  defmodule StructWithOptionalFields do

    use BinStruct

    register_callback &always_not_present/0

    register_callback &present_if_optional_1_present/1,
                      optional_1: :field

    field :optional_1, :uint8, optional_by: &always_not_present/0
    field :optional_2, :uint8, optional_by: &present_if_optional_1_present/1

    def always_not_present(), do: false

    def present_if_optional_1_present(optional_1) when not is_nil(optional_1), do: true
    def present_if_optional_1_present(_optional_1), do: false

  end

  test "dynamically optional fields works" do

    struct =
      StructWithOptionalFields.new(
        optional_1: nil,
        optional_2: nil
      )

    dump = StructWithOptionalFields.dump_binary(struct)

    { :ok, parsed_struct, _rest } = StructWithOptionalFields.parse(dump)

    values = StructWithOptionalFields.decode(parsed_struct)

    %{
      optional_1: nil,
      optional_2: nil
    } = values

  end

end

