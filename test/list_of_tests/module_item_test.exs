defmodule BinStructTest.ListOfTests.ModuleItemTest do

  use ExUnit.Case

  defmodule ItemStruct do

    use BinStruct

    field :value, :uint8

  end

  defmodule StructWithItems do

    use BinStruct

    field :items, { :list_of, ItemStruct }, count: 3

  end

  test "struct with module items works" do

    items = [
      ItemStruct.new(value: 1),
      ItemStruct.new(value: 2),
      ItemStruct.new(value: 3)
    ]

    struct =
      StructWithItems.new(
        items: items
      )

    dump = StructWithItems.dump_binary(struct)

    { :ok, parsed_struct, "" = _rest } = StructWithItems.parse(dump)

    values = StructWithItems.decode(parsed_struct)

    %{
      items: ^items,
    } = values

  end

end

