defmodule BinStructTest.VariantsTest do

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

    field :variant, { :variant_of, [ VariantA, VariantB ] }

  end


  test "struct with variant field works" do

    b = VariantB.new(binary: "321")

    b_dump = VariantB.dump_binary(b)

    { :ok, parsed_struct, _rest } = VariantValueBinStruct.parse(b_dump)

    values = VariantValueBinStruct.decode(parsed_struct)

    %{
      variant: %VariantB{},
    } = values

  end

end

