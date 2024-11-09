defmodule BinStruct.EnumValueByVariantName do

  def find_enum_value_by_variant_name([], _variant_name), do: nil

  def find_enum_value_by_variant_name([ { candidate_variant_value, candidate_variant_name } | _tail ], variant_name)
      when candidate_variant_name == variant_name, do: candidate_variant_value

  def find_enum_value_by_variant_name(enum_def, variant_name) do
    read_enum_value(enum_def, variant_name)
  end

end
