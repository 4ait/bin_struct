defmodule BinStructTest.ListOfTests.UnboundedListsTests.Terminated.UntilLengthByParse.UntilLengthByParseValidateCountTest do

  use ExUnit.Case

  defmodule Item do
    use BinStruct
    alias BinStruct.BuiltIn.TerminatedBinary

    field :binary, { TerminatedBinary, termination: <<0>> }

  end

  defmodule StructWithItemsWithWrongCount do

    use BinStruct

    register_callback &length_by/0
    register_callback &count_by/0

    field :items, { :list_of, Item }, length_by: &length_by/0, count_by: &count_by/0

    defp length_by(), do: 4
    defp count_by(), do: 3

  end

  defmodule StructWithItemsWithProperCount do

    use BinStruct

    register_callback &length_by/0
    register_callback &count_by/0

    field :items, { :list_of, Item }, length_by: &length_by/0, count_by: &count_by/0

    defp length_by(), do: 4
    defp count_by(), do: 2

  end

  test "wrong count check working" do

    data = <<1, 0, 1, 0>>

    { :wrong_data, %{ message: _message, data: _data } } = StructWithItemsWithWrongCount.parse(data)

  end

  test "correct count check working" do

    data = <<1, 0, 1, 0>>

    { :ok, _structs, _rest } = StructWithItemsWithProperCount.parse(data)

  end

end

