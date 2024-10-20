defmodule BinStruct.Macro.TypeConverters.ListOfTypeConverter do


  alias BinStruct.Macro.TypeConverter

  def from_managed_to_unmanaged_list_of({ :list_of, list_of_info }, quoted) do

    %{ item_type: item_type } = list_of_info

    item_binding = { :item, [], __MODULE__ }

    item_encode_expr = TypeConverter.convert_managed_value_to_unmanaged(item_type, item_binding)

    quote do
      Enum.map(
        unquote(quoted),
        fn unquote(item_binding) -> unquote(item_encode_expr)  end
      )
    end

  end


  def from_unmanaged_to_managed_list_of({ :variant_of, _list_of_info }, quoted) do


  end


end