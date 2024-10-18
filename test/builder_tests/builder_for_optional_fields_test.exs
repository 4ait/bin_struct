defmodule BinStructTest.BuilderTests.BuilderForOptionalFieldsTest do

  use ExUnit.Case

  defmodule StructWithAutomaticBuildFields do

    use BinStruct

    register_callback &length_builder/1,
                      dynamic_sized_content: :argument

    field :computed_length, :uint16_be, builder: &length_builder/1, optional: true
    field :dynamic_sized_content, :binary, optional: true

    defp length_builder(nil), do: nil

  end


  test "builder for optional fields works" do

    struct = StructWithAutomaticBuildFields.new()

    %{
      computed_length: nil
    } = StructWithAutomaticBuildFields.decode(struct)

  end

end

