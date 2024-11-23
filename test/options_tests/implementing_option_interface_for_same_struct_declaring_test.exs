defmodule BinStructTest.OptionsTests.ImplementingOptionInterfaceForSameStructDeclaringTest do

  use ExUnit.Case

  defmodule StructWithOptions do

    use BinStruct

    #we are registering option for version of protocol in transport header

    register_option :protocol_version

    #requesting fields required for implement this options interface
    register_callback &impl_options_interface/1, version: :field

    #asking to implement interface PacketHeader (out module name will be our interface)
    #as soon as this header is fully parsed this interface will be implemented and any struct from tree can receive it
    impl_interface StructWithOptions, &impl_options_interface/1

    field :version, {
      :enum,
      %{
        type: :uint8,
        values: [
          { 1, :protocol_ver_1 },
          { 2, :protocol_ver_2 }
        ]
      }
    }

    #actual impl
    defp impl_options_interface(protocol_ver), do: StructWithOptions.option_protocol_version(protocol_ver)

  end


  defmodule Parent do

    use BinStruct

    register_callback &length_by/1, protocol_version: %{ type: :option, interface: StructWithOptions }

    field :option_provider, StructWithOptions

    field :data, :binary, length_by: &length_by/1

    defp length_by(:protocol_ver_1), do: 1

  end



  test "could parse struct which contain child implementing options interface which he declared" do

    struct_implementing_option = StructWithOptions.new(version: :protocol_ver_1)

    parent_struct =
      Parent.new(
        option_provider: struct_implementing_option,
        data: <<1>>
      )

    dump = Parent.dump_binary(parent_struct)

    { :ok, parsed_struct, "" = _rest } = Parent.parse(dump)

    %{ data: <<1>> } = Parent.decode(parsed_struct)

  end


end

