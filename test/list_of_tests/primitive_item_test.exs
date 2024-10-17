defmodule BinStructTest.ListOfTests.PrimitiveItemTest do

  use ExUnit.Case

  defmodule StructWithItems do

    use BinStruct

    field :boolean_items, { :list_of, :bool }, count: 3
    field :integer_items, { :list_of, :uint8 }, count: 3

  end

  test "struct with primitive items works" do

    boolean_items = [
      true,
      true,
      false
    ]

    integer_items = [
      1,
      2,
      3
    ]


    struct =
      StructWithItems.new(
        boolean_items: boolean_items,
        integer_items: integer_items
      )


    dump = StructWithItems.dump_binary(struct)

    StructWithItems.module_code()

    { :ok, parsed_struct, "" = _rest } = StructWithItems.parse(dump)

    IO.inspect(parsed_struct)


    values = StructWithItems.decode(parsed_struct)

    %{
      boolean_items: ^boolean_items,
      integer_items: ^integer_items
    } = values

  end

end

