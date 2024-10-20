defmodule BinStructTest.CustomTypesTests.NonTerminatedCustomTypeTest do

  use ExUnit.Case

  defmodule NonTerminatedCustomType do

    use BinStructCustomType

    def parse_exact_returning_options(bin, _custom_type_args, opts) do
      { :ok, bin, opts }
    end

    def size(_data, _custom_type_args) do
      3
    end

    def dump_binary(data, _custom_type_args) do
      data
    end

    def known_total_size_bytes(_custom_type_args) do
      :unknown
    end

    def to_managed(unmanaged, _custom_type_args), do: unmanaged
    def to_unmanaged(managed, _custom_type_args), do: managed

  end

  defmodule Struct do

    use BinStruct

    field :custom, NonTerminatedCustomType

  end



  test "struct with binary values works" do

    struct = Struct.new(custom: "123")

    dump = Struct.dump_binary(struct)

    { :ok, parsed_struct } = Struct.parse_exact(dump)

    values = Struct.decode(parsed_struct)

    %{
      custom: "123"
    } = values

  end

end

