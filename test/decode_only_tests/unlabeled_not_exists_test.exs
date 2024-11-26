defmodule BinStructTest.DecodeOnlyTests.UnlabeledNotExistTest do

  use ExUnit.Case
  import ExUnit.CaptureLog

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

    { decode_only_result, log } =
      with_log(fn ->
        Struct.decode_only(parsed_struct, [:a])
      end)

    %{ a: 1 } = decode_only_result

    assert log =~ "Use of not compiled decode_only pattern detected."


  end

end

