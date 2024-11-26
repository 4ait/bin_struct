defmodule BinStructTest.DecodeOnlyTests.LabeledTest do

  use ExUnit.Case

  defmodule Struct do

    use BinStruct

    field :a, :uint8
    field :b, :uint8

    compile_decode_only :decode_only_a, [:a]

  end


  test "struct works" do

    struct =
      Struct.new(
        a: 1,
        b: 2
      )

    dump = Struct.dump_binary(struct)

    { :ok, parsed_struct } = Struct.parse_exact(dump)

    %{ a: 1 } = Struct.decode_only_a(parsed_struct)

  end

end

