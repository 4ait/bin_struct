defmodule BinStruct.EnumValueByVariantName do

  @moduledoc """

    Useful in registered_callbacks when library can't achieve automatic type conversion.

    ```

      enum = [
          { 0x01, :a },
          { 0x02, :b }
        ]

      0x01 = BinStruct.EnumValueByVariantName.find_enum_value_by_variant_name(enum, :a)

    ```

  """

  def find_enum_value_by_variant_name([], _variant_name), do: nil

  def find_enum_value_by_variant_name([{candidate_value, candidate_name} | rest], variant_name) do
    if candidate_name == variant_name do
      candidate_value
    else
      find_enum_value_by_variant_name(rest, variant_name)
    end
  end

end
