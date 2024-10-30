defmodule BinStructWithPrimitiveItemList do

  use BinStruct

  field :items, { :list_of, :uint16_be }, length: 1000

end


defmodule Item do

  use BinStruct

  field :value, :uint16_be

end


defmodule BinStructWithStructItemList do

  use BinStruct

  field :items, { :list_of, Item }, length: 1000

end

defmodule BinStructWithStructItemDynamicCallbackList do

  use BinStruct

  alias BinStruct.TypeConversion.TypeConversionUnmanaged

  register_callback &take_while_not_1000_items/1,
                    items: :field

  field :items, { :list_of, Item }, take_while_by: &take_while_not_1000_items/1

  defp take_while_not_1000_items([ 1000 | _prev]), do: :halt
  defp take_while_not_1000_items(_), do: :cont

end