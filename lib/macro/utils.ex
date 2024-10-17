defmodule BinStruct.Macro.Utils do


  alias BinStruct.Macro.Structs.Field

  def is_optional_field( %Field{ opts: opts } ) do
    is_optional_by_opts(opts)
  end

  defp is_optional_by_opts(opts) do
    optional_by = (if opts[:optional_by], do: true, else: false)
    optional = (if opts[:optional], do: true, else: false)

    optional_by || optional

  end

  def bit_size_to_byte_size(size_in_bits) do

    case size_in_bits do

      :unknown -> :unknown

      size_in_bits ->
        case Integer.mod(size_in_bits, 8) do
          0 -> Integer.floor_div(size_in_bits, 8)
          _ -> raise "invalid bitsize of module. Size: #{size_in_bits} could not be packed into byte struct"
        end

    end

  end

end