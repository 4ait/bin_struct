defmodule BinStructTest.ListOfTests.RuntimeBoundariesTests.LengthAndCountTest do

  use ExUnit.Case

  defmodule StructWithItems do

    use BinStruct

    register_callback &length_by/0
    register_callback &count_by/0

    field :items, { :list_of, :binary }, length_by: &length_by/0, count_by: &count_by/0

    defp length_by(), do: 9
    defp count_by(), do: 3

  end

  test "bound by length and count computed" do

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

