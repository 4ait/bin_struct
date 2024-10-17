defmodule BinStructTest.BooleanValuesTest do

  use ExUnit.Case

  defmodule BooleanValuesBinStruct do

    use BinStruct

    field :true_bool, :bool
    field :false_bool, :bool
    field :bool_16_bit, :bool, bits: 16

  end


  test "struct with boolean values works" do

    struct =
      BooleanValuesBinStruct.new(
        true_bool: true,
        false_bool: false,
        bool_16_bit: true
      )

    dump = BooleanValuesBinStruct.dump_binary(struct)

    { :ok, parsed_struct } = BooleanValuesBinStruct.parse_exact(dump)

    values = BooleanValuesBinStruct.decode(parsed_struct)

    %{
      true_bool: true,
      false_bool: false,
      bool_16_bit: true
    } = values

  end


end

