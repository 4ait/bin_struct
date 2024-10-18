defmodule BinStructTest.OptionsTests.ExternallyPassedOptionTest do

  use ExUnit.Case

  defmodule StructWithOptions do

    use BinStruct

    register_option :length

    register_callback &length_by_length_option/1,
                      length: :option

    field :content, :binary, length_by: &length_by_length_option/1

    defp length_by_length_option(length), do: length

  end


  test "could parse struct by externally passed options" do

    content = <<"some content"::binary>>

    struct = StructWithOptions.new(content: content)

    dump = StructWithOptions.dump_binary(struct)

    options = StructWithOptions.option_length(byte_size(content))

    { :ok, parsed_struct, "" = _rest } = StructWithOptions.parse(dump, options)

    values = StructWithOptions.decode(parsed_struct)

    %{
      content: ^content
    } = values

  end


end

