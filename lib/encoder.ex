defmodule BinStruct.Encoder do

  def encoders() do

   quote do

     defp encode_bool(true_of_false, bit_size) when is_boolean(true_of_false) do

       integer_value =
        case true_of_false do
          true -> 1
          false -> 0
        end

       <<integer_value::size(bit_size)-integer-big-unsigned>>

     end

     defp encode_uint8(value) when is_integer(value), do: <<value::8-unsigned>>
     defp encode_int8(value) when is_integer(value), do: <<value::8-signed>>

     defp encode_uint16_be(value) when is_integer(value), do: <<value::16-big-unsigned>>
     defp encode_uint32_be(value) when is_integer(value), do: <<value::32-big-unsigned>>
     defp encode_uint64_be(value) when is_integer(value), do: <<value::64-big-unsigned>>

     defp encode_int16_be(value) when is_integer(value), do: <<value::16-big-signed>>
     defp encode_int32_be(value) when is_integer(value), do: <<value::32-big-signed>>
     defp encode_int64_be(value) when is_integer(value), do: <<value::64-big-signed>>
     defp encode_float32_be(value) when is_float(value), do: <<value::32-big-float>>
     defp encode_float64_be(value) when is_float(value), do: <<value::64-big-float>>

     defp encode_uint16_le(value) when is_integer(value), do: <<value::16-little-unsigned>>
     defp encode_uint32_le(value) when is_integer(value), do: <<value::32-little-unsigned>>
     defp encode_uint64_le(value) when is_integer(value), do: <<value::64-little-unsigned>>
     defp encode_int16_le(value) when is_integer(value), do: <<value::16-little-signed>>
     defp encode_int32_le(value) when is_integer(value), do: <<value::32-little-signed>>
     defp encode_int64_le(value) when is_integer(value), do: <<value::64-little-signed>>
     defp encode_float32_le(value) when is_float(value), do: <<value::32-little-float>>
     defp encode_float64_le(value) when is_float(value), do: <<value::64-little-float>>

     defp encode_uint_variable_bit_size_none(value, bit_size) when is_integer(value),
          do: <<value::size(bit_size)-unsigned>>

     defp encode_uint_variable_bit_size_be(value, bit_size) when is_integer(value),
          do: <<value::size(bit_size)-big-unsigned>>

     defp encode_uint_variable_bit_size_le(value, bit_size) when is_integer(value),
          do: <<value::size(bit_size)-little-unsigned>>

     defp encode_int_variable_bit_size_none(value, bit_size) when is_integer(value),
          do: <<value::size(bit_size)-signed>>

     defp encode_int_variable_bit_size_be(value, bit_size) when is_integer(value),
          do: <<value::size(bit_size)-big-signed>>

     defp encode_int_variable_bit_size_le(value, bit_size) when is_integer(value),
          do: <<value::size(bit_size)-little-signed>>



     defp decode_bool(bitstring, bit_size) when is_bitstring(bitstring) do
       <<integer_value::size(bit_size)-integer-big-unsigned>> = bitstring
       integer_value > 0
     end

     defp decode_uint8(<<value::8-unsigned>>), do: value
     defp decode_int8(<<value::8-signed>>), do: value

     defp decode_uint16_be(<<value::16-big-unsigned>>), do: value
     defp decode_uint32_be(<<value::32-big-unsigned>>), do: value
     defp decode_uint64_be(<<value::64-big-unsigned>>), do: value
     defp decode_int16_be(<<value::16-big-signed>>), do: value
     defp decode_int32_be(<<value::32-big-signed>>), do: value
     defp decode_int64_be(<<value::64-big-signed>>), do: value
     defp decode_float32_be(<<value::32-big-float>>), do: value
     defp decode_float64_be(<<value::64-big-float>>), do: value

     defp decode_uint16_le(<<value::16-little-unsigned>>), do: value
     defp decode_uint32_le(<<value::32-little-unsigned>>), do: value
     defp decode_uint64_le(<<value::64-little-unsigned>>), do: value
     defp decode_int16_le(<<value::16-little-signed>>), do: value
     defp decode_int32_le(<<value::32-little-signed>>), do: value
     defp decode_int64_le(<<value::64-little-signed>>), do: value
     defp decode_float32_le(<<value::32-little-float>>), do: value
     defp decode_float64_le(<<value::64-little-float>>), do: value


     defp decode_uint_variable_bit_size_none(bin, bit_size) when is_integer(bit_size) do
       <<value::size(bit_size)-unsigned>> = bin
       value
     end

     defp decode_uint_variable_bit_size_be(bin, bit_size) when is_integer(bit_size) do
       <<value::size(bit_size)-big-unsigned>> = bin
       value
     end

     defp decode_uint_variable_bit_size_le(bin, bit_size) when is_integer(bit_size)do
       <<value::size(bit_size)-little-unsigned>> = bin
       value
     end

     defp decode_int_variable_bit_size_none(bin, bit_size) when is_integer(bit_size) do
       <<value::size(bit_size)-signed>> = bin
       value
     end

     defp decode_int_variable_bit_size_be(bin, bit_size) when is_integer(bit_size) do
       <<value::size(bit_size)-big-signed>> = bin
       value
     end

     defp decode_int_variable_bit_size_le(bin, bit_size) when is_integer(bit_size) do
       <<value::size(bit_size)-little-signed>> = bin
       value
     end

   end

  end




end


