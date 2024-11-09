defmodule BinStruct.FlagsReader do

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
