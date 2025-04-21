defmodule BinStructTest.VariantOfTests.KnownSize.SelectVariantOfTest do

  use ExUnit.Case

  defmodule VariantA do

    use BinStruct

    field :binary, <<1, 2, 3>>

  end

  defmodule VariantB do

    use BinStruct

    field :binary, <<3, 2, 1>>

  end

  defmodule VariantValueBinStruct do

    use BinStruct

    register_callback &selector/0

    field :variant, { :variant_of, [ VariantA, VariantB ] }, select_variant_by: &selector/0

    defp selector(), do: VariantB

  end


  test "struct with variant field works" do

    b = VariantB.new()

    struct_with_variant = VariantValueBinStruct.new(variant: b)

    dump = VariantValueBinStruct.dump_binary(struct_with_variant)

    { :ok, parsed_struct, _rest } = VariantValueBinStruct.parse(dump)

    values = VariantValueBinStruct.decode(parsed_struct)

    %{
      variant: ^b
    } = values

  end

end

