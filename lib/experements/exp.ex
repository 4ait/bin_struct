defmodule TestStruct do

  #todo implement node sparse algorithm, keep as much distance as we can not breaking connections rules

  use BinStruct

  register_callback &length_by_a/1, a: :field

  field :a, :uint16_be
  field :b, :binary, length_by: &length_by_a/1
  field :c, :binary, length_by: &length_by_a/1

  defp length_by_a(a), do: a

end