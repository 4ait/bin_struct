defmodule BinStructTest.ListOfTests.UnboundedListsTests.NotTerminated.UntilEndByParseStructTest do

  use ExUnit.Case

  defmodule Item do
    use BinStruct
    field :binary, :binary, length: 1
  end

  defmodule StructWithItems do

    use BinStruct
    field :items, { :list_of, Item }

  end

  test "could parse some amount of structs with size in list by parse_exact" do

    items = [
      Item.new(binary: <<1>>),
      Item.new(binary: <<2>>),
      Item.new(binary: <<3>>)
    ]

    struct = StructWithItems.new(items: items)

    dump = StructWithItems.dump_binary(struct)

    { :ok, parsed_struct } = StructWithItems.parse_exact(dump)

    values = StructWithItems.decode(parsed_struct)

    %{
      items: ^items
    } = values

  end

end

