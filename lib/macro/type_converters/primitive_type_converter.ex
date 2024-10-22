defmodule BinStruct.Macro.TypeConverters.PrimitiveTypeConverter do

   def from_managed_to_unmanaged_bool(true_of_false, bit_size) when is_boolean(true_of_false) do

     integer_value =
       case true_of_false do
         true -> 1
         false -> 0
       end

     quote do
       <<unquote(integer_value)::size(unquote(bit_size))-integer-big-unsigned>>
     end

   end

   def from_managed_to_unmanaged_uint8(value) when is_integer(value) do
     quote do
       <<unquote(value)::8-unsigned>>
     end
   end

   def from_managed_to_unmanaged_int8(value) when is_integer(value) do
     quote do
       <<unquote(value)::8-signed>>
     end
   end

   def from_managed_to_unmanaged_uint16_be(value) when is_integer(value), do: <<value::16-big-unsigned>>
   def from_managed_to_unmanaged_uint32_be(value) when is_integer(value), do: <<value::32-big-unsigned>>
   def from_managed_to_unmanaged_uint64_be(value) when is_integer(value), do: <<value::64-big-unsigned>>

   def from_managed_to_unmanaged_int16_be(value) when is_integer(value), do: <<value::16-big-signed>>
   def from_managed_to_unmanaged_int32_be(value) when is_integer(value), do: <<value::32-big-signed>>
   def from_managed_to_unmanaged_int64_be(value) when is_integer(value), do: <<value::64-big-signed>>
   def from_managed_to_unmanaged_float32_be(value) when is_float(value), do: <<value::32-big-float>>
   def from_managed_to_unmanaged_float64_be(value) when is_float(value), do: <<value::64-big-float>>

   def from_managed_to_unmanaged_uint16_le(value) when is_integer(value), do: <<value::16-little-unsigned>>
   def from_managed_to_unmanaged_uint32_le(value) when is_integer(value), do: <<value::32-little-unsigned>>
   def from_managed_to_unmanaged_uint64_le(value) when is_integer(value), do: <<value::64-little-unsigned>>
   def from_managed_to_unmanaged_int16_le(value) when is_integer(value), do: <<value::16-little-signed>>
   def from_managed_to_unmanaged_int32_le(value) when is_integer(value), do: <<value::32-little-signed>>
   def from_managed_to_unmanaged_int64_le(value) when is_integer(value), do: <<value::64-little-signed>>
   def from_managed_to_unmanaged_float32_le(value) when is_float(value), do: <<value::32-little-float>>
   def from_managed_to_unmanaged_float64_le(value) when is_float(value), do: <<value::64-little-float>>

   def from_managed_to_unmanaged_uint_variable_bit_size_none(value, bit_size) when is_integer(value),
        do: <<value::size(bit_size)-unsigned>>

   def from_managed_to_unmanaged_uint_variable_bit_size_be(value, bit_size) when is_integer(value),
        do: <<value::size(bit_size)-big-unsigned>>

   def from_managed_to_unmanaged_uint_variable_bit_size_le(value, bit_size) when is_integer(value),
        do: <<value::size(bit_size)-little-unsigned>>

   def from_managed_to_unmanaged_int_variable_bit_size_none(value, bit_size) when is_integer(value),
        do: <<value::size(bit_size)-signed>>

   def from_managed_to_unmanaged_int_variable_bit_size_be(value, bit_size) when is_integer(value),
        do: <<value::size(bit_size)-big-signed>>

   def from_managed_to_unmanaged_int_variable_bit_size_le(value, bit_size) when is_integer(value),
        do: <<value::size(bit_size)-little-signed>>

   def from_unmanaged_to_managed_bool(bitstring, bit_size) when is_bitstring(bitstring) do
     <<integer_value::size(bit_size)-integer-big-unsigned>> = bitstring
     integer_value > 0
   end

   def from_unmanaged_to_managed_uint8(unmanaged_value) do

     quote do
       <<value::8-unsigned>> = unquote(unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_int8(unmanaged_value) do

     quote do
       <<value::8-signed>> = unquote(unmanaged_value)
       value

     end
   end

   def from_unmanaged_to_managed_uint16_be(<<value::16-big-unsigned>>), do: value
   def from_unmanaged_to_managed_uint32_be(<<value::32-big-unsigned>>), do: value
   def from_unmanaged_to_managed_uint64_be(<<value::64-big-unsigned>>), do: value
   def from_unmanaged_to_managed_int16_be(<<value::16-big-signed>>), do: value
   def from_unmanaged_to_managed_int32_be(<<value::32-big-signed>>), do: value
   def from_unmanaged_to_managed_int64_be(<<value::64-big-signed>>), do: value
   def from_unmanaged_to_managed_float32_be(<<value::32-big-float>>), do: value
   def from_unmanaged_to_managed_float64_be(<<value::64-big-float>>), do: value

   def from_unmanaged_to_managed_uint16_le(<<value::16-little-unsigned>>), do: value
   def from_unmanaged_to_managed_uint32_le(<<value::32-little-unsigned>>), do: value
   def from_unmanaged_to_managed_uint64_le(<<value::64-little-unsigned>>), do: value
   def from_unmanaged_to_managed_int16_le(<<value::16-little-signed>>), do: value
   def from_unmanaged_to_managed_int32_le(<<value::32-little-signed>>), do: value
   def from_unmanaged_to_managed_int64_le(<<value::64-little-signed>>), do: value
   def from_unmanaged_to_managed_float32_le(<<value::32-little-float>>), do: value
   def from_unmanaged_to_managed_float64_le(<<value::64-little-float>>), do: value


   def from_unmanaged_to_managed_uint_variable_bit_size_none(bin, bit_size) when is_integer(bit_size) do
     <<value::size(bit_size)-unsigned>> = bin
     value
   end

   def from_unmanaged_to_managed_uint_variable_bit_size_be(bin, bit_size) when is_integer(bit_size) do
     <<value::size(bit_size)-big-unsigned>> = bin
     value
   end

   def from_unmanaged_to_managed_uint_variable_bit_size_le(bin, bit_size) when is_integer(bit_size)do
     <<value::size(bit_size)-little-unsigned>> = bin
     value
   end

   def from_unmanaged_to_managed_int_variable_bit_size_none(bin, bit_size) when is_integer(bit_size) do
     <<value::size(bit_size)-signed>> = bin
     value
   end

   def from_unmanaged_to_managed_int_variable_bit_size_be(bin, bit_size) when is_integer(bit_size) do
     <<value::size(bit_size)-big-signed>> = bin
     value
   end

   def from_unmanaged_to_managed_int_variable_bit_size_le(bin, bit_size) when is_integer(bit_size) do
     <<value::size(bit_size)-little-signed>> = bin
     value
   end


   def from_unmanaged_to_binary_bool(unmanaged_binary_value, _bit_size), do: unmanaged_binary_value

   def from_unmanaged_to_binary_uint8(unmanaged_binary_value), do: unmanaged_binary_value
   def from_unmanaged_to_binary_int8(unmanaged_binary_value), do: unmanaged_binary_value

   def from_unmanaged_to_binary_uint16_be(unmanaged_binary_value), do: unmanaged_binary_value
   def from_unmanaged_to_binary_uint32_be(unmanaged_binary_value), do: unmanaged_binary_value
   def from_unmanaged_to_binary_uint64_be(unmanaged_binary_value), do: unmanaged_binary_value
   def from_unmanaged_to_binary_int16_be(unmanaged_binary_value), do: unmanaged_binary_value
   def from_unmanaged_to_binary_int32_be(unmanaged_binary_value), do: unmanaged_binary_value
   def from_unmanaged_to_binary_int64_be(unmanaged_binary_value), do: unmanaged_binary_value
   def from_unmanaged_to_binary_float32_be(unmanaged_binary_value), do: unmanaged_binary_value
   def from_unmanaged_to_binary_float64_be(unmanaged_binary_value), do: unmanaged_binary_value

   def from_unmanaged_to_binary_uint16_le(unmanaged_binary_value), do: unmanaged_binary_value
   def from_unmanaged_to_binary_uint32_le(unmanaged_binary_value), do: unmanaged_binary_value
   def from_unmanaged_to_binary_uint64_le(unmanaged_binary_value), do: unmanaged_binary_value
   def from_unmanaged_to_binary_int16_le(unmanaged_binary_value), do: unmanaged_binary_value
   def from_unmanaged_to_binary_int32_le(unmanaged_binary_value), do: unmanaged_binary_value
   def from_unmanaged_to_binary_int64_le(unmanaged_binary_value), do: unmanaged_binary_value
   def from_unmanaged_to_binary_float32_le(unmanaged_binary_value), do: unmanaged_binary_value
   def from_unmanaged_to_binary_float64_le(unmanaged_binary_value), do: unmanaged_binary_value

   def from_unmanaged_to_binary_uint_variable_bit_size_none(unmanaged_binary_value, _bit_size), do: unmanaged_binary_value
   def from_unmanaged_to_binary_uint_variable_bit_size_be(unmanaged_binary_value, _bit_size), do: unmanaged_binary_value
   def from_unmanaged_to_binary_uint_variable_bit_size_le(unmanaged_binary_value, _bit_size), do: unmanaged_binary_value
   def from_unmanaged_to_binary_int_variable_bit_size_none(unmanaged_binary_value, _bit_size), do: unmanaged_binary_value
   def from_unmanaged_to_binary_int_variable_bit_size_be(unmanaged_binary_value, _bit_size), do: unmanaged_binary_value
   def from_unmanaged_to_binary_int_variable_bit_size_le(unmanaged_binary_value, _bit_size), do: unmanaged_binary_value
     
end


