defmodule BinStructTest.OptionsTests.ExternallyPassedOptionByInterfaceTest do

  use ExUnit.Case

  defmodule OptionsInterface do

    use BinStructOptionsInterface

    register_options_interface do
      register_option :length
    end

  end

  defmodule StructWithOptions do

    use BinStruct

    register_callback &length_by_length_option/1,
      length: %{ type: :option, interface: OptionsInterface }

    field :content, :binary, length_by: &length_by_length_option/1

    defp length_by_length_option(length), do: length

  end


  test "could parse struct by externally passed options from interface" do

    content = <<"some content"::binary>>

    struct = StructWithOptions.new(content: content)

    dump = StructWithOptions.dump_binary(struct)

    options = OptionsInterface.option_length(byte_size(content))

    { :ok, parsed_struct, "" = _rest } = StructWithOptions.parse(dump, options)

    values = StructWithOptions.decode(parsed_struct)

    %{
      content: ^content
    } = values

  end


end

