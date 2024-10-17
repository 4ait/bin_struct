defmodule BinStructTest.BooleanValuesTest do

  use ExUnit.Case

  defmodule BoolsBinStruct do

    use BinStruct

    field :true_bool, :bool
    field :false_bool, :bool
    field :bool_16_bit, :bool, bits: 16

  end


  test "struct with boolean values works" do

    struct =
      BoolsBinStruct.new(
        true_bool: true,
        false_bool: false,
        bool_16_bit: true
      )

    values = BoolsBinStruct.decode(struct)

    %{
      true_bool: true,
      false_bool: false,
      bool_16_bit: true
    } = values

  end


end

