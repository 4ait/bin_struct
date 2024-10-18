defmodule BinStructTest.BuilderTests.SimpleTest do

  use ExUnit.Case

  defmodule StructWithAutomaticBuildFields do

    use BinStruct

    register_callback &length_builder/1,
                      dynamic_sized_content: :argument

    field :computed_length, :uint16_be, builder: &length_builder/1

    field :dynamic_sized_content, :binary

    defp length_builder(dynamic_sized_content), do: byte_size(dynamic_sized_content)

  end


  test "builder can build values" do

    dynamic_sized_content = <<1, 2, 3>>

    struct =
      StructWithAutomaticBuildFields.new(
        dynamic_sized_content: dynamic_sized_content
      )

     expected_computed_length = byte_size(dynamic_sized_content)

    %{
      computed_length: ^expected_computed_length
    } = StructWithAutomaticBuildFields.decode(struct)

  end

end

