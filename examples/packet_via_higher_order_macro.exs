#This example is particular useful for any protocol developer!

#Our goal is this example is to setup packet generation for our protocol.
#We will do this once and will be generating it for every structure we need in few lines later
#It will generate for us required fields (like length, crc and so on) and provide context deeply in the tree if we need so


defmodule PacketHeader do

  use BinStruct

  #we are registering option for version of protocol in transport header

  register_option :protocol_version

  #requesting fields required for implement this options interface
  register_callback &impl_options_interface/1, version: :field

  #asking to implement interface PacketHeader (out module name will be our interface)
  #as soon as this header is fully parsed this interface will be implemented and any struct from tree can receive it
  impl_interface PacketHeader, &impl_options_interface/1

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

  field :length, :uint32_be

  #actual impl
  defp impl_options_interface(protocol_ver), do: PacketHeader.option_protocol_version(protocol_ver)

end

defmodule Packet do

  defmacro __using__(_opts) do

    quote do
      import Packet
    end

  end

  defmacro content(content_field_name, content_field_type) do

    quote do

      use BinStruct

      #setting callback for header to be built automatically when we creating new struct
      register_callback &header_builder/2,
                        [
                          { unquote(content_field_name), :field },
                          { :protocol_version, :field }
                        ]

      #will be called in parse time, just forwarding version from header to virtual field of packet for consistency
      register_callback &read_protocol_version/1, header: :field

      #when we parsing data content length will be set to length from header
      register_callback &content_length/1, header: :field

      #simple duplicated from header when parsing
      #when creating new allowing us to specify version manually
      #by default for new structs is set to protocol_ver_2
      virtual :protocol_version, :unspecified,
              read_by: &read_protocol_version/1,
              default: :protocol_ver_2

      # Define the header field
      field :header, PacketHeader, builder: &header_builder/2

      # Define the content field with length_by
      field unquote(content_field_name), unquote(content_field_type),
            length_by: &content_length/1

      # Callback to build the header dynamically
      defp header_builder(content, protocol_version) do
        PacketHeader.new(%{
          version: protocol_version,
          length: unquote(content_field_type).size(content)
        })
      end

      #reading content length from header
      defp content_length(header) do
        %{ length: length } = PacketHeader.decode(header)
        length
      end

      #reading version from header
      defp read_protocol_version(header) do
        %{ version: version } = PacketHeader.decode(header)
        version
      end

    end

  end
end

defmodule StructInsidePacket do
  use BinStruct

  #this struct suppose to work inside our transport packet
  #it has different content according to versions
  #for sake of this "simple" example we not extracting bodies and keeping it simple

  #declare we want to read option
  register_callback &is_protocol_version_1/1, protocol_version: %{ type: :option, interface: PacketHeader }
  register_callback &is_protocol_version_2/1, protocol_version: %{ type: :option, interface: PacketHeader }

  #select body dynamically
  field :protocol_v1_data, :uint32_be, optional_by: &is_protocol_version_1/1
  field :protocol_v2_data, :binary, optional_by: &is_protocol_version_2/1

  #body selection rules
  defp is_protocol_version_1(:protocol_ver_1), do: true
  defp is_protocol_version_1(_), do: false

  defp is_protocol_version_2(:protocol_ver_2), do: true
  defp is_protocol_version_2(_), do: false


end

defmodule StructInsidePacket.Packet do
  use Packet
  content :content, StructInsidePacket
end

#Now as we have set everything up we can work as simple as set desired versions and content

protocol_v1_struct = StructInsidePacket.Packet.new(
  protocol_version: :protocol_ver_1,
  content: StructInsidePacket.new(protocol_v1_data: 123)
)

protocol_v2_struct = StructInsidePacket.Packet.new(
  protocol_version: :protocol_ver_2,
  content: StructInsidePacket.new(protocol_v2_data: "123")
)

#serialize packets to binary

protocol_v1_binary = StructInsidePacket.Packet.dump_binary(protocol_v1_struct)
protocol_v2_binary = StructInsidePacket.Packet.dump_binary(protocol_v2_struct)

#parse from binary simulating unknown packet receiving

{ :ok, parsed_v1_struct, "" = _rest } = StructInsidePacket.Packet.parse(protocol_v1_binary)
{ :ok, parsed_v2_struct, "" = _rest } = StructInsidePacket.Packet.parse(protocol_v2_binary)

decoded_v1 = StructInsidePacket.Packet.decode(parsed_v1_struct)
decoded_v2 = StructInsidePacket.Packet.decode(parsed_v2_struct)

%{
  protocol_version: :protocol_ver_1,
  content: content_of_v1
} = decoded_v1

%{
  protocol_version: :protocol_ver_2,
  content: content_of_v2
} = decoded_v2

StructInsidePacket.decode(content_of_v1) |> IO.inspect(label: "Protocol version 1 content")
StructInsidePacket.decode(content_of_v2) |> IO.inspect(label: "Protocol version 2 content")

#see everything is parsed as expected, protocol versions are shown on decode and respected on parse
