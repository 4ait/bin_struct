defmodule BinStructTest.FlagsValuesBinStruct do

  use ExUnit.Case

  defmodule FlagsValuesBinStruct do

    use BinStruct

    field :flags, {
      :flags,
      %{
        type: :uint32_le,
        values: [
          { 0x00000001, :info_mouse },
          { 0x00000002, :info_disablectrlaltdel },
          { 0x00000008, :info_autologon },
          { 0x00000010, :info_unicode },
          { 0x00000020, :info_maximizeshell },
          { 0x00000040, :info_logonnotify },
          { 0x00000080, :info_compression },
          { 0x00000100, :info_enablewindowskey },
          { 0x00002000, :info_remoteconsoleaudio },
          { 0x00004000, :info_force_encrypted_cs_pdu },
          { 0x00008000, :info_rail },
          { 0x00010000, :info_logonerrors },
          { 0x00020000, :info_mouse_has_wheel },
          { 0x00040000, :info_password_is_sc_pin },
          { 0x00080000, :info_noaudioplayback },
          { 0x00100000, :info_using_saved_creds },
          { 0x00200000, :info_audiocapture },
          { 0x00400000, :info_video_disable },
          { 0x00800000, :info_reserved1 },
          { 0x01000000, :info_reserved2 },
          { 0x02000000, :info_hidef_rail_supported }
        ]
      }
    }

  end


  test "struct with flag values works" do

    flags = [
      :info_mouse,
      :info_rail,
      :info_hidef_rail_supported
    ]

    struct =
      FlagsValuesBinStruct.new(
        flags: flags
      )


    dump = FlagsValuesBinStruct.dump_binary(struct)

    { :ok, parsed_struct } = FlagsValuesBinStruct.parse_exact(dump)

    values = FlagsValuesBinStruct.decode(parsed_struct)

    %{
      flags: ^flags,
    } = values

  end

end

