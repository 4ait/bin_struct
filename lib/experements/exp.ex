
defmodule BenchItem do

  use BinStruct


  register_callback &read_v1/1, a1: :field
  register_callback &a2_length/1, v1: :field


  virtual :v1, :uint32_be, read_by: &read_v1/1

  field :a1, :uint32_be
  field :a2, :binary, length_by: &a2_length/1

  defp read_v1(_a1), do: 1

  defp a2_length(v1), do: v1


end
