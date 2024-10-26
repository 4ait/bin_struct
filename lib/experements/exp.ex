defmodule StructWithPrimitiveItems do

  use BinStruct

  alias BinStruct.TypeConversion.TypeConversionManaged

  register_callback &take_while_by/1, items: %{ type: :field, type_conversion: TypeConversionManaged }

  field :items, { :list_of, :uint16_be }, take_while_by: &take_while_by/1

  defp take_while_by(items) do

    [ recent | _previous ] = items

    case recent do
      3 -> :halt
      _ -> :cont
    end

  end

end