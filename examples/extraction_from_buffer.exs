defmodule ExtractionFromBufferStruct do

  use BinStruct

  #problem: data is in buffer in any order, we know only offset and length of each field
  #problem2: it's utf16 and we can't work this it
  #we will solve exactly step by step as problems acquire

  #while decoding/parsing(on request) we will extract data from buffer to virtual utf16 fields
  #then we will read those to virtual utf8 fields

  #while creating new binaries we will build virtual utf16 fields out of virtual utf8 fields we pass in
  #next we will build lens, offsets and buffer itself out of utf16 data


  #how structure will be decoded ->

  #it will read utf16 out of buffer

  register_callback &read_domain_name_utf16/3,
                    buffer: :field,
                    domain_name_len: :field,
                    domain_name_buffer_offset: :field

  register_callback &read_user_name_utf16/3,
                    buffer: :field,
                    user_name_len: :field,
                    user_name_buffer_offset: :field

  #it will read utf8 out of utf16

  register_callback &read_domain_name_utf8/1, domain_name_utf16: :field
  register_callback &read_user_name_utf8/1, user_name_utf16: :field

  # <- how structure will be decoded



  #how structure will be created ->

  #we creating utf16 out of utf8
  register_callback &build_domain_name_utf16/1, domain_name_utf8: :field
  register_callback &build_user_name_utf16/1, user_name_utf8: :field


  #creating lengths and offsets from utf16
  register_callback &build_domain_name_len/1, domain_name_utf16: :field
  register_callback &build_domain_name_buffer_offset/0

  register_callback &build_user_name_len/1, user_name_utf16: :field

  #we are taking previous entry position in buffer and its length
  register_callback &build_user_name_buffer_offset/2,
                    domain_name_buffer_offset: :field,
                    domain_name_len: :field

  #creating resulting buffer

  register_callback &build_buffer/2,
                    domain_name_utf16: :field,
                    user_name_utf16: :field

  # <- how structure will be created


  #this is our actual desired api to work this, we don't want to know everything else from above perspective
  virtual :domain_name_utf8, :binary, read_by: &read_domain_name_utf8/1
  virtual :user_name_utf8, :binary, read_by: &read_user_name_utf8/1

  #we extracting utf16 virtual fields separately to more readability and to use them as cache
  #to populate both buffer and length while creating new structs
  virtual :domain_name_utf16, :binary, read_by: &read_domain_name_utf16/3, builder: &build_domain_name_utf16/1
  virtual :user_name_utf16, :binary, read_by: &read_user_name_utf16/3, builder: &build_user_name_utf16/1


  # Real shape of binary -> 

  field :domain_name_len, :uint16_le, builder: &build_domain_name_len/1
  field :domain_name_buffer_offset, :uint32_le, builder: &build_domain_name_buffer_offset/0
  field :user_name_len, :uint16_le, builder: &build_user_name_len/1
  field :user_name_buffer_offset, :uint32_le, builder: &build_user_name_buffer_offset/2

  field :buffer, :binary, builder: &build_buffer/2

  # <- Real shape of binary

  #utf16 virtual fields

  #during creation of new struct
  defp build_domain_name_utf16(domain_name_utf8), do: from_utf8_to_utf16_le_non_terminated(domain_name_utf8)
  defp build_user_name_utf16(user_name_utf8), do: from_utf8_to_utf16_le_non_terminated(user_name_utf8)

  #during parse and decode
  defp read_domain_name_utf16(payload, domain_name_len, domain_name_buffer_offset) do
    read_from_buffer(payload, domain_name_len, domain_name_buffer_offset)
  end

  defp read_user_name_utf16(payload, user_name_len, user_name_buffer_offset) do
    read_from_buffer(payload, user_name_len, user_name_buffer_offset)
  end

  #utf8 virtual fields

  defp read_domain_name_utf8(domain_name_utf16), do: from_utf16_le_non_terminated_to_utf8(domain_name_utf16)
  defp read_user_name_utf8(user_name_utf16), do: from_utf16_le_non_terminated_to_utf8(user_name_utf16)

  #length and offset creation

  defp build_domain_name_len(domain_name_utf16), do: byte_size(domain_name_utf16)
  defp build_domain_name_buffer_offset(), do: 0

  defp build_user_name_len(user_name_utf16), do: byte_size(user_name_utf16)
  defp build_user_name_buffer_offset(current_offset, previous_data_length), do: current_offset + previous_data_length

  #how actually buffer will be created

  defp build_buffer(domain_name_utf16, user_name_utf16), do: domain_name_utf16 <> user_name_utf16

  #helpers

  defp read_from_buffer(_buffer, _length = 0, _offset), do: <<>>

  defp read_from_buffer(buffer, length, offset) do

    <<_skip::binary-size(offset), value::binary-size(length), _rest::binary>> = buffer

    value

  end

  defp from_utf16_le_non_terminated_to_utf8(utf_16_terminated_binary)  do
    :unicode.characters_to_binary(utf_16_terminated_binary, { :utf16, :little }, :utf8)
  end

  def from_utf8_to_utf16_le_non_terminated(utf8_binary) do
    :unicode.characters_to_binary(utf8_binary, :utf8, { :utf16, :little })
  end

end


#we are creating new struct to simulate data we would receive
created_struct =
  ExtractionFromBufferStruct.new(
    domain_name_utf8: "some domain",
    user_name_utf8: "some username"
  )

#creating binary
binary_version_of_struct = ExtractionFromBufferStruct.dump_binary(created_struct)

#parsing binary, we are using parse exact in case buffer itself does not have known length
#we can't parse such binaries without top level packet constraints directly
{:ok, parsed_back_struct } = ExtractionFromBufferStruct.parse_exact(binary_version_of_struct)

#decoding to see what is here
decoded = ExtractionFromBufferStruct.decode(parsed_back_struct)

IO.inspect(decoded, label: "Original")

#change some content
changed_struct =
  ExtractionFromBufferStruct.new(
    domain_name_utf8: decoded.domain_name_utf8 <> " yay",
    user_name_utf8: decoded.user_name_utf8 <> " wow"
  )


changed_struct_decoded = ExtractionFromBufferStruct.decode(changed_struct)

#matching everything correctly changed
%{
  domain_name_utf8: "some domain yay",
  user_name_utf8: "some username wow"
} = changed_struct_decoded

IO.inspect(changed_struct_decoded, label: "Changed")

#new binary is ready to send with new content inside!
_ready_to_send_new_binary = ExtractionFromBufferStruct.dump_binary(changed_struct)

#this way we abstracted away internal complexity and working with this data as simple as directly with fields
#we can now perform full cycle or encoding/decoding and extract this structure to be part of something else

