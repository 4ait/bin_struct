defmodule BinStructTest.SeekTests.SeekTest do

  use ExUnit.Case

  defmodule Struct do

    use BinStruct

    alias BinStruct.BuiltIn.Seek

    field :seek_value, { Seek, count: 2 }
    field :value, :binary, length: 1

  end


  test "struct with binary values works" do


    struct = Struct.new(value: <<1, 2>>)

    dump = Struct.dump_binary(struct)

    { :ok, parsed_struct, _rest } = Struct.parse(dump)

    values = Struct.decode(parsed_struct)

    %{
      seek_value: <<1, 2>>,
    } = values

  end

end

