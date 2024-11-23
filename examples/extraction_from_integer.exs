defmodule ExtractionFromIntegerStruct do

  use BinStruct

  alias BinStruct.EnumVariantNameByValue
  alias BinStruct.EnumValueByVariantName
  alias BinStruct.FlagsWriter
  alias BinStruct.FlagsReader

  #problem: there is enum hidden under mask in integer
  #and it's not trivial to extract coz is not on an edge position
  #real struct looks like [  flags_bits ... enum ...flags_bits  ]

  @session_redirection_version_mask 0x0000003C
  @session_redirection_version_mask_shift_offset 2

  #defining values for flags and enum separately, not inlining into declarations

  @flags [
    { 0x00000001, :redirection_supported },
    { 0x00000002, :redirected_sessionid_field_valid },
    { 0x00000040, :redirected_smartcard }
  ]

  @server_session_redirection_version [
    { 0x00, :redirection_version1 },
    { 0x01, :redirection_version2 },
    { 0x02, :redirection_version3 },
    { 0x03, :redirection_version4 },
    { 0x04, :redirection_version5 },
    { 0x05, :redirection_version6 }
  ]


  #how flags will be created during decode/parse(can be requested from any callback inside parse too)
  register_callback &read_flags/1, flags_and_server_session_redirection_version: :field

  #how our enum will be created
  register_callback &read_server_session_redirection_version/1, flags_and_server_session_redirection_version: :field


  #how raw integer will be created from flags and enum during new struct creation
  register_callback &build_flags_and_server_session_redirection_version/2,
                    flags: :field,
                    server_session_redirection_version: :field

  #requsting our clean enum value out of virtual field we just created
  register_callback &is_redirection_version4/1, server_session_redirection_version: :field

  #desired clean api

  virtual :flags, { :flags, %{ type: :uint32_le, values: @flags }}, read_by: &read_flags/1

  virtual :server_session_redirection_version, { :enum, %{ type: :uint, values: @server_session_redirection_version } },
          read_by: &read_server_session_redirection_version/1


  #real part we don't want to work this directly
  field :flags_and_server_session_redirection_version,
        :uint32_le,
        builder: &build_flags_and_server_session_redirection_version/2


  #simulating usage inside parse one of created virtual fields
  #optinal static value will not be created automatically when calling new() unless you pass :present atom to it's field
  #in this example we never setting redirection_version to 4 and not passing :present so it will always be omitted
  field :present_only_if_redirection_version4, "some static value", optional_by: &is_redirection_version4/1

  #implementations to make it happen

  defp read_flags(flags_and_server_session_redirection_version) do

    FlagsReader.read_flags_from_integer(
      @flags,
      flags_and_server_session_redirection_version
    )

  end

  defp read_server_session_redirection_version(flags_and_server_session_redirection_version) do

    integer_under_mask = Bitwise.band(@session_redirection_version_mask, flags_and_server_session_redirection_version)

    integer_under_mask_shifted = Bitwise.bsr(integer_under_mask, @session_redirection_version_mask_shift_offset)

    EnumVariantNameByValue.find_enum_variant_name_by_value(
      @server_session_redirection_version,
      integer_under_mask_shifted
    )

  end


  defp build_flags_and_server_session_redirection_version(flags, server_session_redirection_version) do

    flags_integer =
      FlagsWriter.write_flags_to_integer(
        @flags,
        flags
      )

    integer_under_mask =
      EnumValueByVariantName.find_enum_value_by_variant_name(
        @server_session_redirection_version,
        server_session_redirection_version
      )

    mask_value = Bitwise.bsl(integer_under_mask, @session_redirection_version_mask_shift_offset)

    Bitwise.bor(flags_integer, mask_value)

  end

  defp is_redirection_version4(:redirection_version4 = _server_session_redirection_version), do: true
  defp is_redirection_version4(_server_session_redirection_version), do: false

end

#this extraction will be particular useful when next fields depend on some of this enum or flag value

#we are creating new struct to simulate data we would receive
created_struct =
  ExtractionFromIntegerStruct.new(
    flags: [ :redirection_supported, :redirected_sessionid_field_valid ],
    server_session_redirection_version: :redirection_version6
  )

#creating binary
binary_version_of_struct = ExtractionFromIntegerStruct.dump_binary(created_struct)

#parsing binary
{:ok, parsed_back_struct, "" = _rest} = ExtractionFromIntegerStruct.parse(binary_version_of_struct)

#decoding to see what is here
decoded = ExtractionFromIntegerStruct.decode(parsed_back_struct)

IO.inspect(decoded, label: "Original")

#overriding some content
override_struct =
  ExtractionFromIntegerStruct.new(
    flags: [ :redirected_smartcard | decoded.flags ],
    server_session_redirection_version: :redirection_version5
  )

IO.inspect(ExtractionFromIntegerStruct.decode(override_struct), label: "Override")

#new binary is ready to send with new content inside!
_ready_to_send_new_binary = ExtractionFromIntegerStruct.dump_binary(override_struct)

#this way we abstracted away internal complexity and working with this data as simple as directly with fields
#we can now perform full cycle or encoding/decoding and extract this structure to be part of something else
