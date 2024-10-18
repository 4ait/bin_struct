defmodule BinStructTest.ListOfTests.BoundariesTests.CountAndLengthTest do

  use ExUnit.Case

  defmodule StructWithItems do

    use BinStruct

    field :items, { :list_of, :binary }, count: 3, length: 9

  end

  test "bound by count and length computed" do

    items = [ "123", "234", "345" ]

    struct = StructWithItems.new(items: items)

    dump = StructWithItems.dump_binary(struct)

    { :ok, parsed_struct, "" = _rest } = StructWithItems.parse(dump)

    values = StructWithItems.decode(parsed_struct)

    %{
      items: ^items
    } = values

  end

end

