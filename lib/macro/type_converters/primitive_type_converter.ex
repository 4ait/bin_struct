defmodule BinStruct.Macro.TypeConverters.PrimitiveTypeConverter do

  def primitive_type_converters() do

   quote do

     defp from_managed_to_unmanaged_bool(true_of_false, bit_size) when is_boolean(true_of_false) do

       integer_value =
         case true_of_false do
           true -> 1
           false -> 0
         end

       <<integer_value::size(bit_size)-integer-big-unsigned>>

     end

     defp from_managed_to_unmanaged_uint8(value) when is_integer(value), do: <<value::8-unsigned>>
     defp from_managed_to_unmanaged_int8(value) when is_integer(value), do: <<value::8-signed>>

     defp from_managed_to_unmanaged_uint16_be(value) when is_integer(value), do: <<value::16-big-unsigned>>
     defp from_managed_to_unmanaged_uint32_be(value) when is_integer(value), do: <<value::32-big-unsigned>>
     defp from_managed_to_unmanaged_uint64_be(value) when is_integer(value), do: <<value::64-big-unsigned>>

     defp from_managed_to_unmanaged_int16_be(value) when is_integer(value), do: <<value::16-big-signed>>
     defp from_managed_to_unmanaged_int32_be(value) when is_integer(value), do: <<value::32-big-signed>>
     defp from_managed_to_unmanaged_int64_be(value) when is_integer(value), do: <<value::64-big-signed>>
     defp from_managed_to_unmanaged_float32_be(value) when is_float(value), do: <<value::32-big-float>>
     defp from_managed_to_unmanaged_float64_be(value) when is_float(value), do: <<value::64-big-float>>

     defp from_managed_to_unmanaged_uint16_le(value) when is_integer(value), do: <<value::16-little-unsigned>>
     defp from_managed_to_unmanaged_uint32_le(value) when is_integer(value), do: <<value::32-little-unsigned>>
     defp from_managed_to_unmanaged_uint64_le(value) when is_integer(value), do: <<value::64-little-unsigned>>
     defp from_managed_to_unmanaged_int16_le(value) when is_integer(value), do: <<value::16-little-signed>>
     defp from_managed_to_unmanaged_int32_le(value) when is_integer(value), do: <<value::32-little-signed>>
     defp from_managed_to_unmanaged_int64_le(value) when is_integer(value), do: <<value::64-little-signed>>
     defp from_managed_to_unmanaged_float32_le(value) when is_float(value), do: <<value::32-little-float>>
     defp from_managed_to_unmanaged_float64_le(value) when is_float(value), do: <<value::64-little-float>>

     defp from_managed_to_unmanaged_uint_variable_bit_size_none(value, bit_size) when is_integer(value),
          do: <<value::size(bit_size)-unsigned>>

     defp from_managed_to_unmanaged_uint_variable_bit_size_be(value, bit_size) when is_integer(value),
          do: <<value::size(bit_size)-big-unsigned>>

     defp from_managed_to_unmanaged_uint_variable_bit_size_le(value, bit_size) when is_integer(value),
          do: <<value::size(bit_size)-little-unsigned>>

     defp from_managed_to_unmanaged_int_variable_bit_size_none(value, bit_size) when is_integer(value),
          do: <<value::size(bit_size)-signed>>

     defp from_managed_to_unmanaged_int_variable_bit_size_be(value, bit_size) when is_integer(value),
          do: <<value::size(bit_size)-big-signed>>

     defp from_managed_to_unmanaged_int_variable_bit_size_le(value, bit_size) when is_integer(value),
          do: <<value::size(bit_size)-little-signed>>

     defp from_unmanaged_to_managed_bool(bitstring, bit_size) when is_bitstring(bitstring) do
       <<integer_value::size(bit_size)-integer-big-unsigned>> = bitstring
       integer_value > 0
     end

     defp from_unmanaged_to_managed_uint8(<<value::8-unsigned>>), do: value
     defp from_unmanaged_to_managed_int8(<<value::8-signed>>), do: value

     defp from_unmanaged_to_managed_uint16_be(<<value::16-big-unsigned>>), do: value
     defp from_unmanaged_to_managed_uint32_be(<<value::32-big-unsigned>>), do: value
     defp from_unmanaged_to_managed_uint64_be(<<value::64-big-unsigned>>), do: value
     defp from_unmanaged_to_managed_int16_be(<<value::16-big-signed>>), do: value
     defp from_unmanaged_to_managed_int32_be(<<value::32-big-signed>>), do: value
     defp from_unmanaged_to_managed_int64_be(<<value::64-big-signed>>), do: value
     defp from_unmanaged_to_managed_float32_be(<<value::32-big-float>>), do: value
     defp from_unmanaged_to_managed_float64_be(<<value::64-big-float>>), do: value

     defp from_unmanaged_to_managed_uint16_le(<<value::16-little-unsigned>>), do: value
     defp from_unmanaged_to_managed_uint32_le(<<value::32-little-unsigned>>), do: value
     defp from_unmanaged_to_managed_uint64_le(<<value::64-little-unsigned>>), do: value
     defp from_unmanaged_to_managed_int16_le(<<value::16-little-signed>>), do: value
     defp from_unmanaged_to_managed_int32_le(<<value::32-little-signed>>), do: value
     defp from_unmanaged_to_managed_int64_le(<<value::64-little-signed>>), do: value
     defp from_unmanaged_to_managed_float32_le(<<value::32-little-float>>), do: value
     defp from_unmanaged_to_managed_float64_le(<<value::64-little-float>>), do: value


     defp from_unmanaged_to_managed_uint_variable_bit_size_none(bin, bit_size) when is_integer(bit_size) do
       <<value::size(bit_size)-unsigned>> = bin
       value
     end

     defp from_unmanaged_to_managed_uint_variable_bit_size_be(bin, bit_size) when is_integer(bit_size) do
       <<value::size(bit_size)-big-unsigned>> = bin
       value
     end

     defp from_unmanaged_to_managed_uint_variable_bit_size_le(bin, bit_size) when is_integer(bit_size)do
       <<value::size(bit_size)-little-unsigned>> = bin
       value
     end

     defp from_unmanaged_to_managed_int_variable_bit_size_none(bin, bit_size) when is_integer(bit_size) do
       <<value::size(bit_size)-signed>> = bin
       value
     end

     defp from_unmanaged_to_managed_int_variable_bit_size_be(bin, bit_size) when is_integer(bit_size) do
       <<value::size(bit_size)-big-signed>> = bin
       value
     end

     defp from_unmanaged_to_managed_int_variable_bit_size_le(bin, bit_size) when is_integer(bit_size) do
       <<value::size(bit_size)-little-signed>> = bin
       value
     end


     defp from_unmanaged_to_binary_bool(unmanaged_binary_value, _bit_size), do: unmanaged_binary_value

     defp from_unmanaged_to_binary_uint8(unmanaged_binary_value), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_int8(unmanaged_binary_value), do: unmanaged_binary_value

     defp from_unmanaged_to_binary_uint16_be(unmanaged_binary_value), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_uint32_be(unmanaged_binary_value), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_uint64_be(unmanaged_binary_value), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_int16_be(unmanaged_binary_value), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_int32_be(unmanaged_binary_value), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_int64_be(unmanaged_binary_value), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_float32_be(unmanaged_binary_value), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_float64_be(unmanaged_binary_value), do: unmanaged_binary_value

     defp from_unmanaged_to_binary_uint16_le(unmanaged_binary_value), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_uint32_le(unmanaged_binary_value), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_uint64_le(unmanaged_binary_value), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_int16_le(unmanaged_binary_value), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_int32_le(unmanaged_binary_value), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_int64_le(unmanaged_binary_value), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_float32_le(unmanaged_binary_value), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_float64_le(unmanaged_binary_value), do: unmanaged_binary_value

     defp from_unmanaged_to_binary_uint_variable_bit_size_none(unmanaged_binary_value, _bit_size), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_uint_variable_bit_size_be(unmanaged_binary_value, _bit_size), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_uint_variable_bit_size_le(unmanaged_binary_value, _bit_size), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_int_variable_bit_size_none(unmanaged_binary_value, _bit_size), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_int_variable_bit_size_be(unmanaged_binary_value, _bit_size), do: unmanaged_binary_value
     defp from_unmanaged_to_binary_int_variable_bit_size_le(unmanaged_binary_value, _bit_size), do: unmanaged_binary_value

   end

  end

end


