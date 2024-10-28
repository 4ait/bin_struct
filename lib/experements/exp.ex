defmodule StructWithPrimitiveItems do

  use BinStruct

  alias BinStruct.TypeConversion.TypeConversionManaged


  register_option :option_name

  register_callback &take_while_by/2,
                    items: %{ type: :field, type_conversion: TypeConversionManaged },
                    option_name: :option

  field :items, { :list_of, :uint16_be }, take_while_by: &take_while_by/2

  defp take_while_by(items, option_name) do

    [ recent | _previous ] = items

    case recent do
      3 ->
        if option_name do
          :halt
        else
          :cont
        end
      _ -> :cont
    end

  end

end