defmodule IHDRChunk do

  use BinStruct

  alias BinStruct.PrimitiveEncoder

  field :length, { :static, PrimitiveEncoder.uint32_be(13) }

  field :type, "IHDR"

  field :width, :uint32_be
  field :height, :uint32_be

  field :bit_depth, {
    :enum,
    %{
      type: :uint8,
      values: [
        { 1, :bit_depth_1 },
        { 2, :bit_depth_2 },
        { 4, :bit_depth_4 },
        { 8, :bit_depth_8 },
        { 16, :bit_depth_16 },
      ]
    }
  }

  field :color_type, {
    :enum,
    %{
      type: :uint8,
      values: [
        { 0, :grayscale },
        { 2, :truecolor },
        { 3, :indexed_color_palette_based },
        { 4, :grayscale_with_alpha },
        { 6, :truecolor_with_alpha },
      ]
    }
  }

  field :compression_method, {
    :enum,
    %{
      type: :uint8,
      values: [
        { 0, :deflate },
      ]
    }
  }

  field :filter_method, {
    :enum,
    %{
      type: :uint8,
      values: [
        { 0, :adaptive_filtering },
      ]
    }
  }

  field :interlace_method, {
    :enum,
    %{
      type: :uint8,
      values: [
        { 0, :no_interlace },
        { 1, :adam7_interlace }
      ]
    }
  }


  field :crc, :uint32_be

end


defmodule RawPatternMatch do

  alias BinStruct.EnumVariantNameByValue
  alias BinStruct.PrimitiveEncoder

  def parse(bin) do

    length = PrimitiveEncoder.uint32_be(13)

    <<
      ^length::binary,
      "IHDR",
      width::32-integer-big-unsigned,
      height::32-integer-big-unsigned,
      bit_depth::8-integer-unsigned,
      color_type::8-integer-unsigned,
      compression_method::8-integer-unsigned,
      filter_method::8-integer-unsigned,
      interlace_method::8-integer-unsigned,
      crc::32-integer-big-unsigned,
      rest::binary
    >> = bin


    bit_depth_enum = [
      { 1, :bit_depth_1 },
      { 2, :bit_depth_2 },
      { 4, :bit_depth_4 },
      { 8, :bit_depth_8 },
      { 16, :bit_depth_16 }
    ]

    color_type_enum = [
      { 0, :grayscale },
      { 2, :truecolor },
      { 3, :indexed_color_palette_based },
      { 4, :grayscale_with_alpha },
      { 6, :truecolor_with_alpha },
    ]

    compression_method_enum = [
        { 0, :deflate },
      ]

    filter_method_enum = [
      { 0, :adaptive_filtering },
    ]

    interlace_method_enum = [
      { 0, :no_interlace },
      { 1, :adam7_interlace }
    ]

    result = %{
      length: 13,
      type: "IHDR",
      width: width,
      height: height,
      bit_depth: EnumVariantNameByValue.find_enum_variant_name_by_value(bit_depth_enum, bit_depth),
      color_type: EnumVariantNameByValue.find_enum_variant_name_by_value(color_type_enum, color_type),
      compression_method: EnumVariantNameByValue.find_enum_variant_name_by_value(compression_method_enum,compression_method),
      filter_method: EnumVariantNameByValue.find_enum_variant_name_by_value(filter_method_enum, filter_method),
      interlace_method: EnumVariantNameByValue.find_enum_variant_name_by_value(interlace_method_enum, interlace_method),
      crc: crc
    }


    { :ok, result, rest }

  end


end

defmodule BinaryValuesBench do

  def benchmark() do

    # Simulating different binary data that could be received from the network
    inputs = %{
      "input" => IHDRChunk.new(
        width: 512,
        height: 512,
        bit_depth: :bit_depth_8,
        color_type: :truecolor,
        compression_method: :deflate,
        filter_method: :adaptive_filtering,
        interlace_method: :no_interlace,
        crc: 0
      ) |> IHDRChunk.dump_binary()
    }

    Benchee.run(
      %{
        "binstruct" => (fn bin ->

          { :ok, parsed_struct, "" = _rest } = IHDRChunk.parse(bin)

          IHDRChunk.decode(parsed_struct)

        end),

        "raw_pattern" => (fn bin ->
                             { :ok, _parsed_struct, "" = _rest } = RawPatternMatch.parse(bin)
                        end),
      },
      inputs: inputs
    )
  end

end

BinaryValuesBench.benchmark()