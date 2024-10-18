defmodule BinStructTest.ListOfTests.UnboundedListsTests.Terminated.UntilCountByParseTest do

  use ExUnit.Case

  defmodule Item do
    use BinStruct
    field :binary, :binary, termination: <<0>>
  end

  defmodule StructWithItems do

    use BinStruct

    register_callback &count_by/0

    field :items, { :list_of, Item }, count_by: &count_by/0

    defp count_by(), do: 3

  end

  test "count parse terminated items by count_by" do

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

