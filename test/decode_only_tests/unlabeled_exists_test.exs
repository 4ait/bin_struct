defmodule BinStructTest.DecodeOnlyTests.UnlabeledExistTest do

  use ExUnit.Case

  defmodule Struct do

    use BinStruct

    field :a, :uint8
    field :b, :uint8

    compile_decode_only [:a]

  end


  test "struct works" do

    struct =
      Struct.new(
        a: 1,
        b: 2
      )


    dump = Struct.dump_binary(struct)

    { :ok, parsed_struct } = Struct.parse_exact(dump)

    %{ a: 1} = Struct.decode_only(parsed_struct, [:a])

  end

end

