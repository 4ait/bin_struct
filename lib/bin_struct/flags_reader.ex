defmodule BinStruct.FlagsReader do

  @moduledoc """

    Useful in registered_callbacks when library can't achieve automatic type conversion.

    ```

      flags = [
        { 0x01, :flag_a },
        { 0x02, :flag_b }
      ]

      integer_flags_writen_to = BinStruct.FlagsWriter.write_flags_to_integer(flags, [ :flag_a ])

      [ :flag_a ] = BinStruct.FlagsReader.read_flags_from_integer(flags, integer_flags_writen_to)

    ```

  """

  def read_flags_from_integer([], _integer), do: []

  def read_flags_from_integer([{flag_mask, flag} | rest], integer) do

    is_set = Bitwise.band(integer, flag_mask) > 0

    if is_set do
      [ flag | read_flags_from_integer(rest, integer)]
    else
      read_flags_from_integer(rest, integer)
    end

  end

end
