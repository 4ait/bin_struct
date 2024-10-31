defmodule BinStructTest.ListOfTests.UnboundedListsTests.Terminated.
          TakeWhileByCallbackByRuntimeItemSizeBinaryConversionTest do

  use ExUnit.Case

  defmodule Item do
    use BinStruct

    field :binary, :binary

  end

  defmodule StructWithItemSizeDefinedAtRuntime do

    use BinStruct

    alias BinStruct.TypeConversion.TypeConversionBinary

    register_callback &item_size/0

    register_callback &take_while_by/1,
                      items: %{ type: :field, type_conversion: TypeConversionBinary }

    field :items, { :list_of, Item },
          take_while_by: &take_while_by/1,
          item_size_by: &item_size/0

    defp take_while_by(items) do

      [ recent | _previous ] = items

      case recent do
        <<3>> -> :halt
        _ -> :cont
      end

    end

    defp item_size(), do: 1


  end

  test "could parse items with runtime defined size by take_while_by" do

    items = [ Item.new(binary: <<1>>), Item.new(binary: <<2>>), Item.new(binary: <<3>>) ]

    struct = StructWithItemSizeDefinedAtRuntime.new(items: items)

    dump = StructWithItemSizeDefinedAtRuntime.dump_binary(struct)

    { :ok, parsed_struct, "" = _rest } = StructWithItemSizeDefinedAtRuntime.parse(dump)

    values = StructWithItemSizeDefinedAtRuntime.decode(parsed_struct)

    %{
      items: ^items
    } = values

  end

end

