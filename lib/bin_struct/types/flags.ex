defmodule BinStruct.Types.Flags do

  @moduledoc """

  ## Defining struct with flags using integer mask

    Current implementation support flags extraction up to 64 bits long integer

    ```

      iex> defmodule IntegerMaskFlags do
      ...>   use BinStruct
      ...>   field :value, {
      ...>    :flags,
      ...>    %{
      ...>     type: :uint32_le,
      ...>     values: [
      ...>       { 0x00000001, :info_mouse },
      ...>       { 0x00000002, :info_disablectrlaltdel }
      ...>     ]
      ...>    }
      ...>  }
      ...> end
      ...>
      ...> IntegerMaskFlags.new(value: [:info_mouse, :info_disablectrlaltdel])
      ...> |> IntegerMaskFlags.dump_binary()
      ...> |> IntegerMaskFlags.parse()
      ...> |> then(fn {:ok, struct, _rest } -> struct end)
      ...> |> IntegerMaskFlags.decode()
      %{ value: [:info_mouse, :info_disablectrlaltdel] }


    ```

    I found it's counterintuitively but preferred way to define enums using mask, not position.
    You can change endianness from little to big and it will be work the same, automatically reversing all positions.

    Below is to remember list of supported masks for developers. Library checks its valid mask,
    (covering only 1 bit and never overlaps) so don't worry you will not be able to mistaken it.

    ```

      def supported_masking_values(value) do

        case value do
            0x01 -> 1
            0x02 -> 2
            0x04 -> 3
            0x08 -> 4
            0x10 -> 5
            0x20 -> 6
            0x40 -> 7
            0x80 -> 8
            0x100 -> 9
            0x200 -> 10
            0x400 -> 11
            0x800 -> 12
            0x1000 -> 13
            0x2000 -> 14
            0x4000 -> 15
            0x8000 -> 16
            0x10000 -> 17
            0x20000 -> 18
            0x40000 -> 19
            0x80000 -> 20
            0x100000 -> 21
            0x200000 -> 22
            0x400000 -> 23
            0x800000 -> 24
            0x1000000 -> 25
            0x2000000 -> 26
            0x4000000 -> 27
            0x8000000 -> 28
            0x10000000 -> 29
            0x20000000 -> 30
            0x40000000 -> 31
            0x80000000 -> 32
            0x100000000 -> 33
            0x200000000 -> 34
            0x400000000 -> 35
            0x800000000 -> 36
            0x1000000000 -> 37
            0x2000000000 -> 38
            0x4000000000 -> 39
            0x8000000000 -> 40
            0x10000000000 -> 41
            0x20000000000 -> 42
            0x40000000000 -> 43
            0x80000000000 -> 44
            0x100000000000 -> 45
            0x200000000000 -> 46
            0x400000000000 -> 47
            0x800000000000 -> 48
            0x1000000000000 -> 49
            0x2000000000000 -> 50
            0x4000000000000 -> 51
            0x8000000000000 -> 52
            0x10000000000000 -> 53
            0x20000000000000 -> 54
            0x40000000000000 -> 55
            0x80000000000000 -> 56
            0x100000000000000 -> 57
            0x200000000000000 -> 58
            0x400000000000000 -> 59
            0x800000000000000 -> 60
            0x1000000000000000 -> 61
            0x2000000000000000 -> 62
            0x4000000000000000 -> 63
            0x8000000000000000 -> 64
          end

      end

    ```

  ## Variable bit size

    ```

      iex> defmodule IntegerVariableBitSizeMaskFlags do
      ...>   use BinStruct
      ...>   field :value, {
      ...>    :flags,
      ...>    %{
      ...>     type: :uint_le,
      ...>     values: [
      ...>       { 0x00000001, :info_mouse },
      ...>       { 0x00000002, :info_disablectrlaltdel }
      ...>     ]
      ...>    }
      ...>  }, bits: 24
      ...> end
      ...>
      ...> IntegerVariableBitSizeMaskFlags.new(value: [:info_mouse, :info_disablectrlaltdel])
      ...> |> IntegerVariableBitSizeMaskFlags.dump_binary()
      ...> |> IntegerVariableBitSizeMaskFlags.parse()
      ...> |> then(fn {:ok, struct, _rest } -> struct end)
      ...> |> IntegerVariableBitSizeMaskFlags.decode()
      %{ value: [:info_mouse, :info_disablectrlaltdel] }

    ```

  """

end
