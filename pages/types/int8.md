# int8

8 bit signed integer

```

  iex> defmodule Struct do
  ...>   use BinStruct
  ...>   field :value, :int8
  ...> end
  ...>
  ...> Struct.new(value: -1)
  ...> |> Struct.dump_binary()
  ...> |> Struct.parse()
  ...> |> then(fn {:ok, struct, _rest } -> struct end)
  ...> |> Struct.decode()
  %{ value: -1 }

```
