defmodule BinStructTest.DynamicValidationTest do

  use ExUnit.Case

  defmodule StructMatchingBinaryPattern do

    use BinStruct

    register_callback &check_if_starting_with_pattern/1,
                      binary: :field

    field :binary, :binary,
          termination: <<0>>,
          validate_by: &check_if_starting_with_pattern/1

    defp check_if_starting_with_pattern(binary) do
      String.starts_with?(binary, "Pattern:")
    end

  end



  test "struct with variant field works" do

    correct_binary = "Pattern: 123"
    incorrect_binary = "not a pattern"

    correct_source_binary = <<correct_binary::binary, 0>>
    incorrect_source_binary = <<incorrect_binary::binary, 0>>

    { :ok, parsed_struct, _rest } = StructMatchingBinaryPattern.parse(correct_source_binary)

    values = StructMatchingBinaryPattern.decode(parsed_struct)

    %{
      binary: ^correct_binary
    } = values

    { :wrong_data, ^incorrect_binary } = StructMatchingBinaryPattern.parse(incorrect_source_binary)

  end

end

