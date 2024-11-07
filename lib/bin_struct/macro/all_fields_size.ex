defmodule BinStruct.Macro.AllFieldsSize do

  alias BinStruct.Macro.FieldSize
  alias BinStruct.Macro.BitSizeConverter

  def get_all_fields_size_bytes(fields) do

    size_in_bits =
      Enum.reduce_while(
        fields,
        _size_in_bits = 0,
        fn field, acc ->

          field_size_in_bits = FieldSize.field_size_bits(field)

          case field_size_in_bits do
            field_size_in_bits when is_integer(field_size_in_bits) -> { :cont, acc + field_size_in_bits }
            :unknown -> { :halt, :unknown }
          end

        end
      )

    BitSizeConverter.bit_size_to_byte_size(size_in_bits)

  end


end