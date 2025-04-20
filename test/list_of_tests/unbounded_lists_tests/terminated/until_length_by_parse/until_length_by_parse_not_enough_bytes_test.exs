defmodule BinStructTest.ListOfTests.UnboundedListsTests.Terminated.UntilLengthByParse.UntilLengthByParseNotEnoughBytesTest do

  use ExUnit.Case

  defmodule Item do
    use BinStruct
    alias BinStruct.BuiltIn.TerminatedBinary

    field :binary, { TerminatedBinary, termination: <<0>> }

  end

  defmodule StructWithItems do

    use BinStruct

    register_callback &length_by/0

    field :items, { :list_of, Item }, length_by: &length_by/0

    defp length_by(), do: 3

  end

  test "correctly returns not enough bytes on insufficient input" do

    :not_enough_bytes = StructWithItems.parse(<<1, 2, 3>>)

  end

end

