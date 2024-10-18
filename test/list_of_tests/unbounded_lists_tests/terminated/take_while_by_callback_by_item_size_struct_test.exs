defmodule BinStructTest.ListOfTests.UnboundedListsTests.Terminated.TakeWhileByCallbackByItemSizeStructTest do

  use ExUnit.Case

  defmodule Item do
    use BinStruct
    field :binary, :binary, length: 1
  end

  defmodule StructWithItems do

    use BinStruct

    register_callback &take_while_by/1, items: :field

    field :items, { :list_of, Item }, take_while_by: &take_while_by/1

    defp take_while_by(items) do

      [ recent | _previous ] = items

      case recent.binary do
        <<3>> -> :halt
        _ -> :cont
      end

    end

  end

  test "count parse structs with item_size by take_while_by" do

    items = [
      Item.new(binary: <<1>>),
      Item.new(binary: <<2>>),
      Item.new(binary: <<3>>)
    ]

    struct = StructWithItems.new(items: items)

    dump = StructWithItems.dump_binary(struct)

    { :ok, parsed_struct, "" = _rest } = StructWithItems.parse(dump)

    values = StructWithItems.decode(parsed_struct)

    %{
      items: ^items
    } = values

  end


end

