# int16_le

16 bit low endian signed integer

```elixir

  iex> defmodule Struct do
  ...>   use BinStruct
  ...>   field :value, :int16_le
  ...> end
  ...>
  ...> Struct.new(value: -1)
  ...> |> Struct.dump_binary()
  ...> |> Struct.parse()
  ...> |> then(fn {:ok, struct, _rest } -> struct end)
  ...> |> Struct.decode()
  %{ value: -1 }

```
