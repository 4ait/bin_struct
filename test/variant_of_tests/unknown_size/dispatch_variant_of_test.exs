defmodule BinStructTest.VariantOfTests.UnknownSize.DispatchVariantOfTest do

  use ExUnit.Case

  defmodule VariantA do
    use BinStruct

    alias BinStruct.BuiltIn.TerminatedBinary


    field :code, <<1>>

    field :data, { TerminatedBinary, termination: <<0>> }

  end

  defmodule VariantB do
    use BinStruct
    alias BinStruct.BuiltIn.TerminatedBinary

    field :code, <<2>>

    field :data, { TerminatedBinary, termination: <<0>> }
  end

  defmodule VariantC do
    use BinStruct
    alias BinStruct.BuiltIn.TerminatedBinary

    field :code, <<3>>

    field :data, { TerminatedBinary, termination: <<0>> }
  end

  defmodule StructWithVariant do
    use BinStruct

    field :variant, {
      :variant_of, [
        VariantA,
        VariantB,
        VariantC
      ]
    }

  end


  test "struct with variant field works" do

    b = VariantB.new(data: <<1, 2, 3>>)

    struct_with_variant = StructWithVariant.new(variant: b)

    dump = StructWithVariant.dump_binary(struct_with_variant)

    { :ok, parsed_struct, _rest } = StructWithVariant.parse(dump)

    values = StructWithVariant.decode(parsed_struct)

    %{
      variant: ^b
    } = values

  end

end

