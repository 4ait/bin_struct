defmodule BinStructTest.DecodeSingleTests.SingleFieldDecodeTest do

  use ExUnit.Case

  defmodule Struct do

    use BinStruct

    field :a, :uint8
    field :b, :uint8

    compile_decode_singe :decode_a, :a

  end

  test "struct works" do

    struct =
      Struct.new(
        a: 1,
        b: 2
      )

    dump = Struct.dump_binary(struct)

    { :ok, parsed_struct } = Struct.parse_exact(dump)

    1 = Struct.decode_a(parsed_struct)

  end

end

