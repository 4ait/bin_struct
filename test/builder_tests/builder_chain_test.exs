defmodule BinStructTest.BuilderTests.BuilderChainTest do

  use ExUnit.Case

  defmodule StructWithAutomaticBuildFields do

    use BinStruct

    register_callback &computed_value_1_builder/0

    register_callback &computed_value_2_builder/1,
                      computed_value_1: :field

    register_callback &computed_value_breaking_order/2,
                      computed_value_1: :field,
                      computed_value_2: :field

    field :computed_value_breaking_order, :uint16_be, builder: &computed_value_breaking_order/2
    field :computed_value_1, :uint16_be, builder: &computed_value_1_builder/0
    field :computed_value_2, :uint16_be, builder: &computed_value_2_builder/1

    defp computed_value_1_builder(), do: 1
    defp computed_value_2_builder(computed_value_1), do: computed_value_1 + 1

    defp computed_value_breaking_order(computed_value_1, computed_value_2) do
      computed_value_1 + computed_value_2
    end

  end


  test "builders can be called in chain with automatic order resolutions" do

    struct = StructWithAutomaticBuildFields.new()

    %{
      computed_value_breaking_order: 3,
      computed_value_1: 1,
      computed_value_2: 2
    } = StructWithAutomaticBuildFields.decode(struct)

  end

end

