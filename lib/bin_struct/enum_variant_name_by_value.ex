defmodule BinStruct.EnumVariantNameByValue do

  def find_enum_variant_name_by_value([], _enum_value), do: nil

  def find_enum_variant_name_by_value([{candidate_value, candidate_name} | rest], enum_value) do
    if candidate_value == enum_value do
      candidate_name
    else
      find_enum_variant_name_by_value(rest, enum_value)
    end
  end

end
