defmodule BinStructTest.OptionsTests.PassingOptionsForCustomTypeTest do

  use ExUnit.Case

  defmodule ChildCustomTypeUsingOption do

    use BinStructCustomType

    register_option :a
    register_option :b

    def parse_returning_options(bin, _custom_type_args, opts) do

      %{
        ChildCustomTypeUsingOption => %{ a: a }
      } = opts

      if a !== 1 do

        raise "option to custom type not passed properly"

      end

      { :ok, bin, "", opts }

    end

    def size(data, _custom_type_args), do: byte_size(data)
    def dump_binary(data, _custom_type_args), do: data
    def known_total_size_bytes(_custom_type_args), do: :unknown
    def from_unmanaged_to_managed(unmanaged, _custom_type_args), do: unmanaged
    def from_managed_to_unmanaged(managed, _custom_type_args), do: managed

  end

  defmodule ParentPassingOptions do

    use BinStruct

    register_option :external_opt

    register_callback &callback/2,
                    f: :field,
                    external_opt: :option

    field :f, :uint8
    field :child, ChildCustomTypeUsingOption

    impl_interface ChildCustomTypeUsingOption, &callback/2, for: :child

    defp callback(f, external_opt) do
      ChildCustomTypeUsingOption.option_a(f)
      |> ChildCustomTypeUsingOption.option_b(external_opt)
    end

  end


  test "could pass options within same struct with for: :field_name construct" do

    child = <<1>>

    parent = ParentPassingOptions.new(f: 1, child: child)

    parent_binary = ParentPassingOptions.dump_binary(parent)

    { :ok, parsed_parent, "" } = ParentPassingOptions.parse(parent_binary)

    %ParentPassingOptions{
      child: ^child
    } = parsed_parent

  end


end

