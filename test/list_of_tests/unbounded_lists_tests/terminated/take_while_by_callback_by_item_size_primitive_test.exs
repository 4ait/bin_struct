defmodule BinStructTest.ListOfTests.UnboundedListsTests.Terminated.TakeWhileByCallbackByItemSizePrimitiveTest do

  use ExUnit.Case

  defmodule StructWithPrimitiveItems do

    use BinStruct

    alias BinStruct.Macro.Structs.TypeConversionManaged

    register_callback &take_while_by/1, items: %{ type: :field, type_conversion: TypeConversionManaged }

    field :items, { :list_of, :uint16_be }, take_while_by: &take_while_by/1

    defp take_while_by(items) do

      [ recent | _previous ] = items

      case recent do
        3 -> :halt
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

