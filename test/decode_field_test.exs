defmodule BinStructTest.DecodeFieldTest do

  use ExUnit.Case

  defmodule Struct do

    use BinStruct

    field :a, :uint8
    field :b, :uint8

  end


  test "struct works" do

    struct =
      Struct.new(
        a: 1,
        b: 2
      )


    dump = Struct.dump_binary(struct)

    { :ok, parsed_struct } = Struct.parse_exact(dump)

    1 = Struct.decode_field(parsed_struct, :a)
    2 = Struct.decode_field(parsed_struct, :b)

  end

end

