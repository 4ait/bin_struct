defmodule BinStruct.FlagsWriter do

  def write_flags_to_integer(flags_def, set_flags) do
    do_write_flags_to_integer(flags_def, set_flags, 0)
  end

  defp do_write_flags_to_integer([], _set_flags, accumulated_value), do: accumulated_value

  defp do_write_flags_to_integer([{flag_mask, flag} | rest], set_flags, accumulated_value) do

    new_mask = if flag in set_flags, do: flag_mask, else: 0

    updated_value = Bitwise.bor(accumulated_value, new_mask)

    do_write_flags_to_integer(rest, set_flags, updated_value)
  end

end
