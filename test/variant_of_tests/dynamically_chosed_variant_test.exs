defmodule BinStructTest.VariantOfTests.SimpleVariantOfTest do

  use ExUnit.Case

  defmodule Token do

    use BinStruct

    register_callback &check_if_starting_with_token_pattern/1,
                      binary: :field

    field :binary, :binary,
          termination: <<0>>,
          validate_by: &check_if_starting_with_token_pattern/1

    defp check_if_starting_with_token_pattern(binary) do
      String.starts_with?(binary, "starting with particular sentence")
    end


  end


  test "struct with variant field works" do

    a = VariantA.new(binary: "some binary")
    b = VariantB.new(binary: "starting with particular sentence some binary")

    struct_with_variant = VariantValueBinStruct.new(variant: b)

    dump = VariantValueBinStruct.dump_binary(struct_with_variant)

    { :ok, parsed_struct, _rest } = VariantValueBinStruct.parse(dump)

    values = VariantValueBinStruct.decode(parsed_struct)

    %{
      variant: ^b
    } = values

  end

end

