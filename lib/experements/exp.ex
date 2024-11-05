defmodule TestStruct do

  use BinStruct

  register_callback &length_by_a/1, a: :field

  field :a, :uint16_be
  field :b, :binary, length_by: &length_by_a/1
  field :c, :binary, length_by: &length_by_a/1

  defp length_by_a(a), do: a

end