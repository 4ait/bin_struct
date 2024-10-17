defmodule BinStructTest.BinaryValuesTest do

  use ExUnit.Case

  defmodule BinaryValuesBinStruct do

    use BinStruct

    field :binary_fixed_lenght, :binary, length: 3
    field :binary_terminated, :binary, termination: <<0, 0, 0>>
    field :binary_unbounded, :binary

  end


  test "struct with binary values works" do

    bin = "123"

    struct =
      BinaryValuesBinStruct.new(
        binary_fixed_lenght: bin,
        binary_terminated: bin,
        binary_unbounded: bin
      )


    dump = BinaryValuesBinStruct.dump_binary(struct)

    { :ok, parsed_struct } = BinaryValuesBinStruct.parse_exact(dump)

    values = BinaryValuesBinStruct.decode(parsed_struct)

    %{
      binary_fixed_lenght: ^bin,
      binary_terminated: ^bin,
      binary_unbounded: ^bin
    } = values

  end

end

