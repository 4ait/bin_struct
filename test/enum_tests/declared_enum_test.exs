defmodule BinStructTest.EnumsTests.DeclaredEnumTest do

  use ExUnit.Case

  defmodule DeclaredEnumValuesBinStruct do

    use BinStruct

    field :enum, {
      :enum,
      %{
        type: :uint16_le,
        values: [
          { 0x0004, :high_color_4bpp },
          { 0x0008, :high_color_8bpp },
          { 0x000F, :high_color_15bpp },
          { 0x0010, :high_color_16bpp },
          { 0x0018, :high_color_24bpp }
        ]
      }
    }

    field :enum_as_binary, {
      :enum,
      %{
        type: :binary,
        values: [
          { "A", :high_color_4bpp },
          { "B", :high_color_8bpp },
          { "C", :high_color_15bpp },
          { "D", :high_color_16bpp },
          { "E", :high_color_24bpp }
        ]
      }
    }, length: 1

  end


  test "struct with declared enum values works" do

    enum_variant = :high_color_15bpp

    struct =
      DeclaredEnumValuesBinStruct.new(
        enum: enum_variant,
        enum_as_binary: enum_variant
      )

    dump = DeclaredEnumValuesBinStruct.dump_binary(struct)

    { :ok, parsed_struct } = DeclaredEnumValuesBinStruct.parse_exact(dump)

    values = DeclaredEnumValuesBinStruct.decode(parsed_struct)

    %{
      enum: ^enum_variant,
      enum_as_binary: ^enum_variant,
    } = values

  end

end

