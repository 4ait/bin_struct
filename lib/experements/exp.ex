defmodule StructWithItems do

  use BinStruct

  register_callback &count_by/0
  register_callback &item_size_by/0

  field :items, { :list_of, :binary }, count_by: &count_by/0, item_size_by: &item_size_by/0

  defp count_by(), do: 3
  defp item_size_by(), do: 3

end