defmodule BinStructTest.ListOfTests.BinaryItemTest do

  use ExUnit.Case

  defmodule StructWithItems do

    use BinStruct

    field :binary_items, { :list_of, :binary }, count: 3, item_size: 3

  end

  test "struct with binary items works" do

    binary_items = [ "123", "234", "345" ]

    struct =
      StructWithItems.new(
        binary_items: binary_items
      )

    dump = StructWithItems.dump_binary(struct)

    { :ok, parsed_struct, "" = _rest } = StructWithItems.parse(dump)

    values = StructWithItems.decode(parsed_struct)

    %{
      binary_items: ^binary_items
    } = values

  end

end

