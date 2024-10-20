defmodule BinStructTest.Asn1Tests.Asn1Test do

  use ExUnit.Case

  defmodule BinStructWithAsn1 do

    use BinStruct

    alias BinStruct.BuiltIn.Asn1

    field :asn1, { Asn1, asn1_module: :"TEST-ASN1", asn1_type: :"SimpleType" }

  end


  test "struct with asn1 field works" do

    asn1_data = 1

    struct = BinStructWithAsn1.new(asn1: asn1_data)

    dump = BinStructWithAsn1.dump_binary(struct)

    { :ok, parsed_struct, "" = _rest } = BinStructWithAsn1.parse(dump)

    values = BinStructWithAsn1.decode(parsed_struct)

    %{
      asn1: ^asn1_data
    } = values

  end

end

