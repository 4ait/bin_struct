defmodule BinStructTest.Asn1Tests.TailedBytesCorrectlyHandledTest do

  use ExUnit.Case

  defmodule BinStructWithAsn1 do

    use BinStruct

    alias BinStruct.BuiltIn.Asn1

    field :asn1, { Asn1, asn1_module: :"TEST-ASN1", asn1_type: :"SimpleType" }

  end


  test "bytes tail correctly returned after asn1 parse" do

    asn1_data = 1

    struct = BinStructWithAsn1.new(asn1: asn1_data)

    dump = BinStructWithAsn1.dump_binary(struct)

    tail = <<1, 2, 3>>

    dump_with_tail = dump <> tail

    { :ok, parsed_struct, ^tail } = BinStructWithAsn1.parse(dump_with_tail)

    values = BinStructWithAsn1.decode(parsed_struct)

    %{
      asn1: ^asn1_data
    } = values

  end

end

