# uint_le

Variable size low endian unsigned integer

## Variable bit size

```

iex> defmodule Struct do
...>   use BinStruct
...>   field :value, :uint_le, bits: 24
...> end
...>
...> Struct.new(value: 1)
...> |> Struct.dump_binary()
...> |> Struct.parse()
...> |> then(fn {:ok, struct, _rest } -> struct end)
...> |> Struct.decode()
%{ value: 1 }

```
