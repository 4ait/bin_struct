defmodule BinStructTest.StaticValueTest do

  use ExUnit.Case

  defmodule BinStructWithStaticValue do

    use BinStruct
    field :static_value, <<123>>
  end


  test "struct with binary values works" do

    struct = BinStructWithStaticValue.new()

    dump = BinStructWithStaticValue.dump_binary(struct)

    { :ok, parsed_struct } = BinStructWithStaticValue.parse_exact(dump)

    values = BinStructWithStaticValue.decode(parsed_struct)

    %{
      static_value: <<123>>
    } = values

  end

end

