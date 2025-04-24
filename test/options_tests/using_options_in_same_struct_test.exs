defmodule BinStructTest.OptionsTests.UsingOptionsInSameStructTest do

  use ExUnit.Case

  defmodule ChildUsingOption do

    use BinStruct

    register_callback &validate_f1_equal_option_a2/2,
                      f1: :field,
                      a: :option

    register_option :a

    field :f1, :uint8, validate_by: &validate_f1_equal_option_a2/2

    defp validate_f1_equal_option_a2(f1, a), do: f1 == a

  end

  defmodule ParentPassingOptions do

    use BinStruct

    register_callback &callback/1,
                    f: :field

    field :f, :uint8
    field :child, ChildUsingOption

    impl_interface ChildUsingOption, &callback/1, for: :child

    defp callback(f) do
      ChildUsingOption.option_a(f)
    end

  end


  test "could pass options within same struct with for: :field_name construct" do

    child = ChildUsingOption.new(f1: 1)

    parent = ParentPassingOptions.new(f: 1, child: child)

    parent_binary = ParentPassingOptions.dump_binary(parent)

    { :ok, parsed_parent, "" } = ParentPassingOptions.parse(parent_binary)

    %ParentPassingOptions{
      child: ^child
    } = parsed_parent

  end


end

