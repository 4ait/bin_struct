defmodule BinStructTest.KnownSizeBytesTest do

  use ExUnit.Case

  defmodule StructWithOptionalByField do

    use BinStruct

    register_callback &is_length2_present/1, length1: :field

    field :length1, :binary, length: 1
    field :length2, :binary, length: 1, optional_by: &is_length2_present/1

    defp is_length2_present(length1)  do
      <<most_significant_bit::1, _rest_bits::7>> = length1
      most_significant_bit > 0
    end

  end

  defmodule StructWithOptionalField do

    use BinStruct

    field :length1, :binary, length: 1
    field :length2, :binary, length: 1, optional: true

  end

  test "struct with optional field does not have known size bytes" do

    assert(StructWithOptionalByField.known_total_size_bytes() == :unknown)
    assert(StructWithOptionalField.known_total_size_bytes() == :unknown)

  end


end
