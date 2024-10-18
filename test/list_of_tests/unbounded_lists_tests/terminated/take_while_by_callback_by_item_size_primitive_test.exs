defmodule BinStructTest.ListOfTests.UnboundedListsTests.Terminated.TakeWhileByCallbackByItemSizePrimitiveTest do

  use ExUnit.Case

  defmodule StructWithPrimitiveItems do

    use BinStruct

    register_callback &take_while_by/1, items: :field

    field :items, { :list_of, :uint16_be }, take_while_by: &take_while_by/1

    defp take_while_by(items) do

      [ recent | _previous ] = items

      expected_value_to_stop = BinStructStaticValue.uint16_be(3)

      case recent do
        ^expected_value_to_stop -> :halt
        _ -> :cont
      end

    end

  end

  test "could parse primitives by take_while_by" do

    items = [ 1, 2, 3 ]

    struct = StructWithPrimitiveItems.new(items: items)

    dump = StructWithPrimitiveItems.dump_binary(struct)

    { :ok, parsed_struct, "" = _rest } = StructWithPrimitiveItems.parse(dump)

    values = StructWithPrimitiveItems.decode(parsed_struct)

    %{
      items: ^items
    } = values

  end

end

