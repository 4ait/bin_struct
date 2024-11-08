defmodule BinStructTest.EnumsTests.EvaluatedEnumTest do

  use ExUnit.Case

  defmodule EvaluatedEnumValuesBinStruct do

    use BinStruct

    @enum [
      { 0x0004, :high_color_4bpp },
      { 0x0008, :high_color_8bpp },
      { 0x000F, :high_color_15bpp },
      { 0x0010, :high_color_16bpp },
      { 0x0018, :high_color_24bpp }
    ]

    @enum_as_binary [
      { "A", :high_color_4bpp },
      { "B", :high_color_8bpp },
      { "C", :high_color_15bpp },
      { "D", :high_color_16bpp },
      { "E", :high_color_24bpp }
    ]

    field :enum, {
      :enum,
      %{
        type: :uint16_le,
        values: @enum
      }
    }

    field :enum_as_binary, {
      :enum,
      %{
        type: :binary,
        values: @enum_as_binary
      }
    }, length: 1

  end


  test "struct with declared enum values works" do

    enum_variant = :high_color_15bpp

    struct =
      EvaluatedEnumValuesBinStruct.new(
        enum: enum_variant,
        enum_as_binary: enum_variant
      )


    dump = EvaluatedEnumValuesBinStruct.dump_binary(struct)

    { :ok, parsed_struct } = EvaluatedEnumValuesBinStruct.parse_exact(dump)

    values = EvaluatedEnumValuesBinStruct.decode(parsed_struct)

    %{
      enum: ^enum_variant,
      enum_as_binary: ^enum_variant,
    } = values

  end

end

