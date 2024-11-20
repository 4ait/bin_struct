defmodule BinStruct.Macro.TypeConverters.PrimitiveTypeConverter do

  @moduledoc false

   def from_managed_to_unmanaged_bool(true_of_false_quoted, bit_size) do

     quote do

       integer_value =
         case unquote(true_of_false_quoted) do
           true -> 1
           false -> 0
         end

       <<integer_value::size(unquote(bit_size))-integer-big-unsigned>>
     end

   end

   def from_managed_to_unmanaged_uint8(value_quoted) do

     quote do
       <<unquote(value_quoted)::8-unsigned>>
     end

   end

   def from_managed_to_unmanaged_int8(value_quoted) do

     quote do
       <<unquote(value_quoted)::8-signed>>
     end

   end

   def from_managed_to_unmanaged_uint16_be(value_quoted) do

     quote do
       <<unquote(value_quoted)::16-big-unsigned>>
     end

   end
   def from_managed_to_unmanaged_uint32_be(value_quoted) do

     quote do
       <<unquote(value_quoted)::32-big-unsigned>>
     end

   end

   def from_managed_to_unmanaged_uint64_be(value_quoted) do

     quote do
       <<unquote(value_quoted)::64-big-unsigned>>
     end

   end

   def from_managed_to_unmanaged_int16_be(value_quoted) do

     quote do
       <<unquote(value_quoted)::16-big-signed>>
     end

   end
   def from_managed_to_unmanaged_int32_be(value_quoted) do

     quote do
       <<unquote(value_quoted)::32-big-signed>>
     end

   end
   def from_managed_to_unmanaged_int64_be(value_quoted) do

     quote do
       <<unquote(value_quoted)::64-big-signed>>
     end

   end
   def from_managed_to_unmanaged_float32_be(value_quoted) do

     quote do
       <<unquote(value_quoted)::32-big-float>>
     end

   end
   def from_managed_to_unmanaged_float64_be(value_quoted) do

     quote do
       <<unquote(value_quoted)::64-big-float>>
     end

   end

   def from_managed_to_unmanaged_uint16_le(value_quoted) do

     quote do
       <<unquote(value_quoted)::16-little-unsigned>>
     end

   end

   def from_managed_to_unmanaged_uint32_le(value_quoted) do

     quote do
       <<unquote(value_quoted)::32-little-unsigned>>
     end

   end

   def from_managed_to_unmanaged_uint64_le(value_quoted) do

     quote do
       <<unquote(value_quoted)::64-little-unsigned>>
     end

   end
   def from_managed_to_unmanaged_int16_le(value_quoted) do

     quote do
       <<unquote(value_quoted)::16-little-signed>>
     end

   end
   def from_managed_to_unmanaged_int32_le(value_quoted) do

     quote do
       <<unquote(value_quoted)::32-little-signed>>
     end

   end
   def from_managed_to_unmanaged_int64_le(value_quoted) do

     quote do
       <<unquote(value_quoted)::64-little-signed>>
     end

   end
   def from_managed_to_unmanaged_float32_le(value_quoted) do

     quote do
       <<unquote(value_quoted)::32-little-float>>
     end

   end
   def from_managed_to_unmanaged_float64_le(value_quoted)  do

     quote do
       <<unquote(value_quoted)::64-little-float>>
     end

   end

   def from_managed_to_unmanaged_uint_variable_bit_size_none(value_quoted, bit_size)  do

     quote do
       <<unquote(value_quoted)::size(unquote(bit_size))-unsigned>>
     end

   end

   def from_managed_to_unmanaged_uint_variable_bit_size_be(value_quoted, bit_size)  do

     quote do
       <<unquote(value_quoted)::size(unquote(bit_size))-big-unsigned>>
     end

   end

   def from_managed_to_unmanaged_uint_variable_bit_size_le(value_quoted, bit_size)  do

     quote do
       <<unquote(value_quoted)::size(unquote(bit_size))-little-unsigned>>
     end

   end

   def from_managed_to_unmanaged_int_variable_bit_size_none(value_quoted, bit_size)  do

     quote do
       <<unquote(value_quoted)::size(unquote(bit_size))-signed>>
     end
   end

   def from_managed_to_unmanaged_int_variable_bit_size_be(value_quoted, bit_size)  do

     quote do
       <<unquote(value_quoted)::size(unquote(bit_size))-big-signed>>
     end

   end

   def from_managed_to_unmanaged_int_variable_bit_size_le(value_quoted, bit_size)  do

     quote do
       <<unquote(value_quoted)::size(unquote(bit_size))-little-signed>>
     end

   end

   def from_unmanaged_to_managed_bool(quoted_unmanaged_value, bit_size) do

     quote do

       <<integer_value::size(unquote(bit_size))-integer-big-unsigned>> = unquote(quoted_unmanaged_value)
       integer_value > 0

     end

   end

   def from_unmanaged_to_managed_uint8(quoted_unmanaged_value) do

     quote do
       <<value::8-unsigned>> = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_int8(quoted_unmanaged_value) do

     quote do
       <<value::8-signed>> = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_uint16_be(quoted_unmanaged_value) do

     quote do
       <<value::16-big-unsigned>> = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_uint32_be(quoted_unmanaged_value) do

     quote do
       <<value::32-big-unsigned>> = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_uint64_be(quoted_unmanaged_value) do

     quote do
       <<value::64-big-unsigned>> = unquote(quoted_unmanaged_value)
       value
     end

   end


   def from_unmanaged_to_managed_int16_be(quoted_unmanaged_value) do

     quote do
       <<value::16-big-signed>> = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_int32_be(quoted_unmanaged_value) do

     quote do
       <<value::32-big-signed>> = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_int64_be(quoted_unmanaged_value) do

     quote do
       <<value::64-big-signed>> = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_float32_be(quoted_unmanaged_value) do

     quote do
       <<value::32-big-float>> = unquote(quoted_unmanaged_value)
       value
     end

   end


   def from_unmanaged_to_managed_float64_be(quoted_unmanaged_value) do

     quote do
       <<value::64-big-float>> = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_uint16_le(quoted_unmanaged_value) do

     quote do
       <<value::16-little-unsigned>> = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_uint32_le(quoted_unmanaged_value) do

     quote do
       <<value::32-little-unsigned>> = unquote(quoted_unmanaged_value)
       value
     end

   end


   def from_unmanaged_to_managed_uint64_le(quoted_unmanaged_value) do

     quote do
       <<value::64-little-unsigned>> = unquote(quoted_unmanaged_value)
       value
     end

   end


   def from_unmanaged_to_managed_int16_le(quoted_unmanaged_value) do

     quote do
       <<value::16-little-signed>> = unquote(quoted_unmanaged_value)
       value
     end

   end


   def from_unmanaged_to_managed_int32_le(quoted_unmanaged_value) do

     quote do
       <<value::32-little-signed>> = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_int64_le(quoted_unmanaged_value) do

     quote do
       <<value::64-little-signed>> = unquote(quoted_unmanaged_value)
       value
     end

   end


   def from_unmanaged_to_managed_float32_le(quoted_unmanaged_value) do

     quote do
       <<value::32-little-float>> = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_float64_le(quoted_unmanaged_value) do

     quote do
       <<value::64-little-float>> = unquote(quoted_unmanaged_value)
       value
     end

   end


   def from_unmanaged_to_managed_uint_variable_bit_size_none(quoted_unmanaged_value, bit_size) when is_integer(bit_size) do

     quote do
       <<value::size(unquote(bit_size))-unsigned>> = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_uint_variable_bit_size_be(quoted_unmanaged_value, bit_size) when is_integer(bit_size) do

     quote do
       <<value::size(bit_size)-big-unsigned>>  = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_uint_variable_bit_size_le(quoted_unmanaged_value, bit_size) when is_integer(bit_size)do

     quote do
       <<value::size(bit_size)-little-unsigned>> = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_int_variable_bit_size_none(quoted_unmanaged_value, bit_size) when is_integer(bit_size) do

     quote do
       <<value::size(bit_size)>> = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_int_variable_bit_size_be(quoted_unmanaged_value, bit_size) when is_integer(bit_size) do

     quote do
       <<value::size(bit_size)-big-signed>> = unquote(quoted_unmanaged_value)
       value
     end

   end

   def from_unmanaged_to_managed_int_variable_bit_size_le(quoted_unmanaged_value, bit_size) when is_integer(bit_size) do

     quote do
       <<value::size(bit_size)-little-signed>> = unquote(quoted_unmanaged_value)
       value
     end

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


