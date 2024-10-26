defmodule BinStructTest.CustomTypesTests.NonTerminatedCustomTypeTest do

  use ExUnit.Case

  defmodule NonTerminatedCustomType do

    use BinStructCustomType

    def parse_exact_returning_options(bin, _custom_type_args, opts) do
      { :ok, bin, opts }
    end

    def size(data, _custom_type_args) do
      byte_size(data)
    end

    def dump_binary(data, _custom_type_args) do
      data
    end

    def known_total_size_bytes(_custom_type_args) do
      :unknown
    end

    def from_unmanaged_to_managed(unmanaged, _custom_type_args), do: unmanaged
    def from_managed_to_unmanaged(managed, _custom_type_args), do: managed

  end

  defmodule Struct do

    use BinStruct

    field :custom, NonTerminatedCustomType

  end


  test "struct with non terminated (with only parse_exact_returning_options defined) works" do

    struct = Struct.new(custom: "123")

    dump = Struct.dump_binary(struct)

    { :ok, parsed_struct } = Struct.parse_exact(dump)

    values = Struct.decode(parsed_struct)

    %{
      custom: "123"
    } = values

  end

end

