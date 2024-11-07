defmodule BinStructTest.CustomTypesTests.CustomTypeInitArgsTest do

  use ExUnit.Case

  defmodule CustomTypeWithArgs do

    use BinStructCustomType

    def init_args(custom_type_args) do

      args = %{
        test_arg: custom_type_args[:test_arg]
      }

      { :ok, args }

    end

    def parse_returning_options(bin, custom_type_args, opts) do

      %{
        test_arg: :test
      } = custom_type_args

      case bin do
        <<data::3-bytes, rest::binary>> -> { :ok, data, rest, opts }
        _ -> :not_enough_bytes
      end

    end

    def size(data, custom_type_args) do

      %{
        test_arg: :test
      } = custom_type_args

      byte_size(data)
    end

    def dump_binary(data, custom_type_args) do

      %{
        test_arg: :test
      } = custom_type_args

      data
    end

    def known_total_size_bytes(custom_type_args) do

      %{
        test_arg: :test
      } = custom_type_args

      3
    end

    def from_unmanaged_to_managed(unmanaged, custom_type_args) do

      %{
        test_arg: :test
      } = custom_type_args

      unmanaged

    end

    def from_managed_to_unmanaged(managed, custom_type_args) do

      %{
        test_arg: :test
      } = custom_type_args

      managed

    end

  end

  defmodule Struct do

    use BinStruct

    field :custom, { CustomTypeWithArgs, test_arg: :test }

  end


  test "struct with init arguments works" do

    struct = Struct.new(custom: "123")

    dump = Struct.dump_binary(struct)

    { :ok, parsed_struct, "" } = Struct.parse(dump)

    values = Struct.decode(parsed_struct)

    %{
      custom: "123"
    } = values

  end

end

