defmodule BinStructTest.ListOfTests.UnboundedListsTests.Terminated.TakeWhileByCallbackByParseTest do

  use ExUnit.Case

  defmodule Item do
    use BinStruct

    alias BinStruct.BuiltIn.TerminatedBinary

    field :binary, { TerminatedBinary, termination: <<0>> }
  end

  defmodule StructWithItems do

    use BinStruct

    register_callback &take_while_by/1, items: :field

    field :items, { :list_of, Item }, take_while_by: &take_while_by/1

    defp take_while_by(items) do

      [ recent | _previous ] = items

      case recent.binary do
        <<4, 5, 6>> -> :halt
        _ -> :cont
      end

    end

  end

  test "could parse terminated items by while_by" do

    items = [
      Item.new(binary: <<1>>),
      Item.new(binary: <<2, 3>>),
      Item.new(binary: <<4, 5, 6>>)
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

