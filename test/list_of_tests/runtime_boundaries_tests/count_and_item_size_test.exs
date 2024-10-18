defmodule BinStructTest.ListOfTests.RuntimeBoundariesTests.CountAndItemSizeTest do

  use ExUnit.Case

  defmodule StructWithItems do

    use BinStruct

    register_callback &count_by/0
    register_callback &item_size_by/0

    field :items, { :list_of, :binary }, count_by: &count_by/0, item_size_by: &item_size_by/0

    defp count_by(), do: 3
    defp item_size_by(), do: 3

  end

  test "bound by count and item size computed" do

    items = [ "123", "234", "345" ]

    struct = StructWithItems.new(items: items)

    dump = StructWithItems.dump_binary(struct)

    { :ok, parsed_struct, "" = _rest } = StructWithItems.parse(dump)

    values = StructWithItems.decode(parsed_struct)

    %{
      items: ^items
    } = values

  end

end

