defmodule BinStructTest.CustomTypesTests.ExternallyPassedOptionToCustomTypeTest do

  use ExUnit.Case

  defmodule StructOptions do
    use BinStructOptionsInterface

    register_option :from_custom_type_option

  end

  defmodule CustomType do

    use BinStructCustomType

    @type test_option :: :a

    register_option :to_custom_type_option

    def parse_returning_options(bin, _custom_type_args, opts) do

      %{ CustomType => %{ to_custom_type_option: :a } } = opts

      opts = StructOptions.option_from_custom_type_option(opts, 1)

      <<first_byte::1-bytes, rest::binary>> = bin

      { :ok, first_byte, rest, opts }

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

    register_callback &len/1,
                      from_custom_type_option: %{ type: :option, interface: StructOptions }


    field :custom_type, CustomType

    field :bin, :binary, length_by: &len/1

    defp len(from_custom_type_option), do: from_custom_type_option

  end


  test "could parse struct by externally passed options" do

    struct = Struct.new(custom_type: <<1>>, bin: <<2>>)

    dump = Struct.dump_binary(struct)

    options = CustomType.option_to_custom_type_option(:a)

    { :ok, parsed_struct, "" = _rest } = Struct.parse(dump, options)

    values = Struct.decode(parsed_struct)

    %{
      custom_type: <<1>>,
      bin: <<2>>
    } = values

  end


end

