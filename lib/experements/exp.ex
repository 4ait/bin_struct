
defmodule BenchItem do

  use BinStruct


  register_callback &read_length_from_a1/1, a1: :field
  register_callback &create_v1_from_a1/1, a1: :field
  register_callback &create_v2_from_v1/1, v1: :field
  register_callback &read_length_from_v2/1, v2: :field


  virtual :v1, :uint32_be, read_by: &create_v1_from_a1/1
  virtual :v2, :uint32_be, read_by: &create_v2_from_v1/1

  field :a1, :uint32_be
  field :a2, :binary, length_by: &read_length_from_a1/1
  field :a3, :binary, length_by: &read_length_from_v2/1

  defp create_v1_from_a1(_a1), do: 1
  defp create_v2_from_v1(_v1), do: 1

  defp read_length_from_a1(_a1), do: 1
  defp read_length_from_v2(v2), do: v2

end
