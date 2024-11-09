defmodule BinStruct.EnumValueByVariantName do

  def find_enum_value_by_variant_name([], _variant_name), do: nil

  def find_enum_value_by_variant_name([{candidate_value, candidate_name} | rest], variant_name) do
    if candidate_name == variant_name do
      candidate_value
    else
      find_enum_value_by_variant_name(rest, variant_name)
    end
  end

end
