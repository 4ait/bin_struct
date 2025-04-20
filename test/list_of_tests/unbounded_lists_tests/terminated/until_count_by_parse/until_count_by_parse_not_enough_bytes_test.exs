defmodule BinStructTest.ListOfTests.UnboundedListsTests.Terminated.UntilCountByParse.UntilCountByParseNotEnoughBytesTest do

  use ExUnit.Case

  defmodule Item do
    use BinStruct

    alias BinStruct.BuiltIn.TerminatedBinary

    field :binary, { TerminatedBinary, termination: <<0>> }
  end

  defmodule StructWithItems do

    use BinStruct

    register_callback &count_by/0

    field :items, { :list_of, Item }, count_by: &count_by/0

    defp count_by(), do: 3

  end

  test "correctly returns not enough bytes on insufficient input" do

    :not_enough_bytes = StructWithItems.parse(<<1, 2, 3>>)

  end

end

