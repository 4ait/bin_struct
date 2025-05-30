defmodule BinStruct.Macro.TypeConverters.ListOfTypeConverter do

  @moduledoc false

  alias BinStruct.Macro.TypeConverterToUnmanaged
  alias BinStruct.Macro.TypeConverterToBinary
  alias BinStruct.Macro.TypeConverterToManaged

  def from_managed_to_unmanaged_list_of({ :list_of, list_of_info }, quoted) do

    %{ item_type: item_type } = list_of_info

    item_binding = { :item, [], __MODULE__ }

    item_encode_expr = TypeConverterToUnmanaged.convert_managed_value_to_unmanaged(item_type, item_binding)

    quote do
      Enum.map(
        unquote(quoted),
        fn unquote(item_binding) -> unquote(item_encode_expr)  end
      )
    end

  end

  def from_unmanaged_to_managed_list_of({ :list_of, list_of_info }, quoted) do

    %{ item_type: item_type } = list_of_info

    item_access = { :umnanaged_item, [], __MODULE__ }

    quote do

      Enum.map(
        unquote(quoted),
        fn unquote(item_access) ->
          unquote(TypeConverterToManaged.convert_unmanaged_value_to_managed(item_type, item_access))
        end
      )

    end

  end

  def from_unmanaged_to_binary_list_of({ :list_of, list_of_info }, quoted) do

    %{ item_type: item_type } = list_of_info

    item_binding = { :item, [], __MODULE__ }

    item_encode_expr = TypeConverterToBinary.convert_unmanaged_value_to_binary(item_type, item_binding)

    quote do
      Enum.reduce(
        unquote(quoted),
        <<>>,
        fn unquote(item_binding), binary_acc ->
          binary_item = unquote(item_encode_expr)
          <<binary_acc::binary, binary_item::binary>>
        end
      )
    end

  end


end