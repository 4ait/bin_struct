defmodule BinStructTest.ListOfTests.UnboundedListsTests.NotTerminated.UntilEndByParsePrimitiveTest do

  use ExUnit.Case

  defmodule StructWithPrimitiveItems do

    use BinStruct

    field :items, { :list_of, :uint16_be }

  end

  test "could parse some amount of primitives with size in list by parse_exact" do

    items = [
      1,
      2,
      3
    ]

    struct = StructWithPrimitiveItems.new(items: items)

    dump = StructWithPrimitiveItems.dump_binary(struct)

    { :ok, parsed_struct } = StructWithPrimitiveItems.parse_exact(dump)

    values = StructWithPrimitiveItems.decode(parsed_struct)

    %{
      items: ^items
    } = values

  end

end

