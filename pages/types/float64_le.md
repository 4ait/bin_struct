# float64_le

64 bit low endian float

```elixir

  iex> defmodule Struct do
  ...>   use BinStruct
  ...>   field :value, :float64_le
  ...> end
  ...>
  ...> Struct.new(value: 1.0)
  ...> |> Struct.dump_binary()
  ...> |> Struct.parse()
  ...> |> then(fn {:ok, struct, _rest } -> struct end)
  ...> |> Struct.decode()
  %{ value: 1.0 }

```
