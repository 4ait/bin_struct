defmodule BinStructTest.ListOfTests.UnboundedListsTests.Terminated.
          TakeWhileByCallbackByParseBinaryConversionTest do

  use ExUnit.Case

  defmodule Item do
    use BinStruct

    field :value, :uint8

  end

  defmodule StructWithItems do

    use BinStruct

    register_callback &take_while_by/1,
                      items: %{
                        type: :field,
                        type_conversion: BinStruct.TypeConversion.TypeConversionBinary
                      }

    field :items, { :list_of, Item }, take_while_by: &take_while_by/1

    defp take_while_by([ <<3>> | _tail]), do: :halt
    defp take_while_by(_), do: :cont

  end

  test "could parse terminated items by while_by" do

    items = [
      Item.new(value: 1),
      Item.new(value: 2),
      Item.new(value: 3)
    ]

    struct = StructWithItems.new(items: items)

    dump = StructWithItems.dump_binary(struct)

    { :ok, parsed_struct, <<4>> = _rest } = StructWithItems.parse(dump <> <<4>>)

    values = StructWithItems.decode(parsed_struct)

    %{
      items: ^items
    } = values

  end

end

