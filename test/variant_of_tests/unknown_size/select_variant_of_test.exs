defmodule BinStructTest.VariantOfTests.UnknownSize.SelectVariantOfTest do

  use ExUnit.Case

  defmodule VariantA do
    use BinStruct

    alias BinStruct.BuiltIn.TerminatedBinary

    field :data, { TerminatedBinary, termination: <<0>> }

  end

  defmodule VariantB do
    use BinStruct
    alias BinStruct.BuiltIn.TerminatedBinary

    field :data, { TerminatedBinary, termination: <<0>> }
  end

  defmodule VariantC do
    use BinStruct
    alias BinStruct.BuiltIn.TerminatedBinary

    field :data, { TerminatedBinary, termination: <<0>> }
  end

  defmodule StructWithVariant do

    use BinStruct

    register_callback &select_variant_callback/1,
                      selector: :field


    field :selector, :uint8

    field :variant, {
      :variant_of, [
        VariantA,
        VariantB,
        VariantC
      ]
    }, select_variant_by: &select_variant_callback/1

    defp select_variant_callback(selector) do

      case selector do
        1 -> VariantA
        2 -> VariantB
        3 -> VariantC
      end

    end

  end


  test "struct with variant field works" do

    b = VariantB.new(data: <<1, 2, 3>>)

    struct_with_variant = StructWithVariant.new(variant: b, selector: 2)

    dump = StructWithVariant.dump_binary(struct_with_variant)

    { :ok, parsed_struct, _rest } = StructWithVariant.parse(dump)

    values = StructWithVariant.decode(parsed_struct)

    %{
      variant: ^b
    } = values

  end

end

