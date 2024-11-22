defmodule BinStructTest.EnumsTests.DeclaredEnumTest do

  use ExUnit.Case

  defmodule EnumStruct do

    use BinStruct

    field :enum_as_binary, {
      :enum,
      %{
        type: :binary,
        values: [
          { "A", :a }
        ]
      }
    }, length: 1

  end


  test "struct with non existing enum returning wrong data" do

    { :wrong_data, _ } = EnumStruct.parse_exact("B")
    { :ok, %EnumStruct{ enum_as_binary: "A" } } = EnumStruct.parse_exact("A")

  end

end

