
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
        { 6, :truecolor_with_alhpa },
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

defmodule IENDChunk do

  use BinStruct

  alias BinStruct.PrimitiveEncoder

  field :length, { :static, PrimitiveEncoder.uint32_be(0) }

  field :type, "IEND"

  field :data, <<>>

  field :crc, :uint32_be

end


defmodule KnownChunk do

  use BinStruct

  register_callback &data_length/1, length: :field

  field :length, :uint32_be

  field :type, {
    :enum,
    %{
      type: :binary,
      values: [
        "IHDR",
        "PLTE",
        "IDAT",
        "IEND",
        "cHRM",
        "gAMA",
        "iCCP",
        "sBIT",
        "sRGB",
        "bKGD",
        "hIST",
        "tRNS",
        "pHYs",
        "sPLT",
        "tIME",
        "tEXt",
        "zTXt",
        "iTXt"
      ]
    }
  }, length: 4

  field :data, :binary, length_by: &data_length/1

  field :crc, :uint32_be

  defp data_length(length), do: length

end


defmodule UnknownChunk do

  use BinStruct

  register_callback &data_length/1, length: :field

  field :length, :uint32_be

  field :type, :binary, length: 4

  field :data, :binary, length_by: &data_length/1

  field :crc, :uint32_be

  defp data_length(length), do: length

end

defmodule Chunk do

  use BinStruct

  field :chunk, { :variant_of, [ IHDRChunk, IENDChunk, KnownChunk, UnknownChunk ] }

end


defmodule Png do
  use BinStruct

  register_callback &take_while_by/1, chunks: :field

  field :png_signature, <<137, 80, 78, 71, 13, 10, 26, 10>>
  field :chunks, { :list_of, Chunk }, take_while_by: &take_while_by/1

  defp take_while_by([ %Chunk{ chunk: %IENDChunk{} } | _prev]), do: :halt
  defp take_while_by(_), do: :cont

end


elixir_png_file_binary = File.read!("examples/Elixir.png")

{:ok, parsed_struct, "" = _rest} = Png.parse(elixir_png_file_binary)

IO.inspect(parsed_struct)

[ first_chunk | _rest ] = parsed_struct.chunks

IHDRChunk.decode(first_chunk.chunk) |> IO.inspect()