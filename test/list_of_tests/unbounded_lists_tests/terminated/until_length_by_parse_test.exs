defmodule BinStructTest.ListOfTests.UnboundedListsTests.Terminated.UntilLengthByParseTest do

  use ExUnit.Case

  defmodule Item do
    use BinStruct
    field :binary, :binary, termination: <<0>>
  end

  defmodule StructWithItems do

    use BinStruct

    register_callback &length_by/0

    field :items, { :list_of, Item }, length_by: &length_by/0

    defp length_by(), do: 9

  end

  test "could parse terminated items by length_by" do

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

