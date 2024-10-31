defmodule BinStructTest.ModuleTests.DynamicLengthTest do

  use ExUnit.Case

  defmodule Item do
    use BinStruct

    register_callback &length_by/0

    field :binary, :binary, length_by: &length_by/0

    defp length_by(), do: 1

  end

  test "could parse item with dynamic length" do

    { :ok, parsed_struct, <<2, 3>> } = Item.parse(<<1, 2, 3>>)

    values = Item.decode(parsed_struct)

    %{
      binary: <<1>>
    } = values

  end

end

