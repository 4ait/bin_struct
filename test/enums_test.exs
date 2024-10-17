defmodule BinStructTest.EnumsValuesTest do

  use ExUnit.Case

  defmodule EnumsValuesBinStruct do

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

  end


  test "struct with enum values works" do

    enum_variant = :high_color_15bpp

    struct =
      EnumsValuesBinStruct.new(
        enum: enum_variant
      )


    dump = EnumsValuesBinStruct.dump_binary(struct)

    { :ok, parsed_struct } = EnumsValuesBinStruct.parse_exact(dump)

    values = EnumsValuesBinStruct.decode(parsed_struct)

    %{
      enum: ^enum_variant,
    } = values

  end

end

