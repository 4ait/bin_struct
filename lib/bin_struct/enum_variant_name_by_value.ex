defmodule BinStruct.EnumVariantNameByValue do

  @moduledoc """
  Useful in `registered_callbacks` when library can't achieve automatic type conversion.

  ```elixir
  iex> enum = [{ 0x01, :a}, {0x02, :b}]
  ...> BinStruct.EnumVariantNameByValue.find_enum_variant_name_by_value(enum, 0x01)
  :a
  ```
  """

  def find_enum_variant_name_by_value([], _enum_value), do: nil

  def find_enum_variant_name_by_value([{candidate_value, candidate_name} | rest], enum_value) do
    if candidate_value == enum_value do
      candidate_name
    else
      find_enum_variant_name_by_value(rest, enum_value)
    end
  end

end
