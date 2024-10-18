defmodule BinStructTest.Support.UtfEncoder do

    def from_utf16_le_terminated(utf_16_terminated_binary) when byte_size(utf_16_terminated_binary) >= 2 do

      utf_16_terminated_binary_size = byte_size(utf_16_terminated_binary)

      termination = <<0x00, 0x00>>

      unicode_bytes_size = utf_16_terminated_binary_size - byte_size(termination)

      <<unicode_bytes::size(unicode_bytes_size)-bytes, ^termination::binary>> = utf_16_terminated_binary

      :unicode.characters_to_binary(unicode_bytes, { :utf16, :little }, :utf8)

    end

    def to_utf16_le_terminated(utf8_binary) do

      utf16_le_binary = :unicode.characters_to_binary(utf8_binary, :utf8, { :utf16, :little })

      termination = <<0x00, 0x00>>

      <<utf16_le_binary::binary, termination::binary>>

    end

end
