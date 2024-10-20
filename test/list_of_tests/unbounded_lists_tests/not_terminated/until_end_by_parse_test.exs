defmodule BinStructTest.ListOfTests.UnboundedListsTests.NotTerminated.UntilEndByParseTest do

  use ExUnit.Case

  defmodule Item do
    use BinStruct

    alias BinStruct.BuiltIn.TerminatedBinary

    field :binary, { TerminatedBinary, termination: <<0>> }
  end

  defmodule StructWithItems do

    use BinStruct
    field :items, { :list_of, Item }

  end

  test "could parse structs containing some amount of terminated items with parse_exact" do

    items = [
      Item.new(binary: <<1>>),
      Item.new(binary: <<2, 3, 4>>),
      Item.new(binary: <<5, 6, 7, 8>>)
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

