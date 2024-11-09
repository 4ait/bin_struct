defmodule BinStruct.EnumVariantNameByValue do

  def find_enum_variant_name_by_value([], _enum_value), do: nil

  def find_enum_variant_name_by_value([ { candidate_variant_value, candidate_variant_name } | _tail ], enum_value)
      when candidate_variant_value == enum_value, do: candidate_variant_name

  def find_enum_variant_name_by_value(enum_def, enum_value) do
    find_enum_variant_name_by_value(enum_def, enum_value)
  end

end
