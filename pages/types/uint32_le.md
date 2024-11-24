# uint32_le

32 bit low endian unsigned integer

```elixir

iex> defmodule Struct do
...>   use BinStruct
...>   field :value, :uint32_le
...> end
...>
...> Struct.new(value: 1)
...> |> Struct.dump_binary()
...> |> Struct.parse()
...> |> then(fn {:ok, struct, _rest } -> struct end)
...> |> Struct.decode()
%{ value: 1 }

```
