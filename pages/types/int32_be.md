# int32_be

32 bit big endian signed integer

```

  iex> defmodule Struct do
  ...>   use BinStruct
  ...>   field :value, :int32_be
  ...> end
  ...>
  ...> Struct.new(value: -1)
  ...> |> Struct.dump_binary()
  ...> |> Struct.parse()
  ...> |> then(fn {:ok, struct, _rest } -> struct end)
  ...> |> Struct.decode()
  %{ value: -1 }

```
