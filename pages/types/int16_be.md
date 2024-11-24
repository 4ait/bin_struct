# int16_be

16 bit big endian signed integer

```elixir

  iex> defmodule Struct do
  ...>   use BinStruct
  ...>   field :value, :int16_be
  ...> end
  ...>
  ...> Struct.new(value: -1)
  ...> |> Struct.dump_binary()
  ...> |> Struct.parse()
  ...> |> then(fn {:ok, struct, _rest } -> struct end)
  ...> |> Struct.decode()
  %{ value: -1 }

```
