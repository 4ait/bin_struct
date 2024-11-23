# list_of

There is 3 types of list_of supported

## With compile time known bounds

BinStruct needs to know at least 2 params out of length (size in bytes), item size (in bytes) or items count

Item size will be inferred if possible in case its primitive with known size or module with known_total_size_bytes

```

  iex> defmodule CompileTimeKnownStruct do
  ...>   use BinStruct
  ...>   field :items, { :list_of, :uint32_be }, count: 2
  ...> end
  ...>
  ...> CompileTimeKnownStruct.new(items: [ 1, 2 ])
  ...> |> CompileTimeKnownStruct.dump_binary()
  ...> |> CompileTimeKnownStruct.parse()
  ...> |> then(fn {:ok, struct, _rest } -> struct end)
  ...> |> CompileTimeKnownStruct.decode()
  %{ items: [ 1, 2 ] }

```


## With runtime known bounds

Same as with compile time known bounds, but any of 2 bounds could be given via registered callback

Overhead of dynamic bounds comparing to known in compile time almost negligible


```

  iex> defmodule RuntimeStruct do
  ...>   use BinStruct
  ...>
  ...>   register_callback &count/0
  ...>
  ...>   field :items, { :list_of, :uint32_be }, count_by: &count/0
  ...>
  ...>   defp count(), do: 2
  ...> end
  ...>
  ...> RuntimeStruct.new(items: [ 1, 2 ])
  ...> |> RuntimeStruct.dump_binary()
  ...> |> RuntimeStruct.parse()
  ...> |> then(fn {:ok, struct, _rest } -> struct end)
  ...> |> RuntimeStruct.decode()
  %{ items: [ 1, 2 ] }

```

## With only one criteria known

Struct below has only one criteria (item size)

It still can be parsed, but such struct called "not terminated" and only parse_exact/2 function will be generated

So in case to parse this struct caller (manually called by user or nested in another BinStruct) should provide finite input.

```

  iex> defmodule OnlyItemSizeCriteriaStruct do
  ...>   use BinStruct
  ...>   field :items, { :list_of, :uint32_be }
  ...> end
  ...>
  ...> OnlyItemSizeCriteriaStruct.new(items: [ 1, 2 ])
  ...> |> OnlyItemSizeCriteriaStruct.dump_binary()
  ...> |> OnlyItemSizeCriteriaStruct.parse_exact()
  ...> |> then(fn {:ok, struct } -> struct end)
  ...> |> OnlyItemSizeCriteriaStruct.decode()
  %{ items: [ 1, 2 ] }

```

## Without any bounds criteria


It's still possible to parse struct even then we are not know about its size anything, for example

```

    iex> defmodule Item do
    ...>   use BinStruct
    ...>
    ...>   register_callback &len_by/1, len: :field
    ...>
    ...>   field :len, :uint16_be
    ...>   field :value, :binary, length_by: &len_by/1
    ...>
    ...>   defp len_by(len), do: len
    ...> end
    ...>
    ...> defmodule WithoutBoundsStruct do
    ...>   use BinStruct
    ...>   field :items, { :list_of, Item }
    ...> end
    ...>
    ...> WithoutBoundsStruct.new(items: [ Item.new(len: 1, value: "A"), Item.new(len: 1, value: "B"), Item.new(len: 1, value: "C") ])
    ...> |> WithoutBoundsStruct.dump_binary()
    ...> |> WithoutBoundsStruct.parse_exact()
    ...> |> then(fn {:ok, struct } -> struct end)
    ...> |> WithoutBoundsStruct.decode()
    %{ items: [ Item.new(len: 1, value: "A"), Item.new(len: 1, value: "B"), Item.new(len: 1, value: "C") ] }

```


## With manual selection upon dynamic criteria


We can restrict example from "Without any bounds criteria" even future using take_while_by callback to any dynamic criteria

```

    iex> defmodule TakeWhileExampleItem do
    ...>   use BinStruct
    ...>
    ...>   register_callback &len_by/1, len: :field
    ...>
    ...>   field :len, :uint16_be
    ...>   field :value, :binary, length_by: &len_by/1
    ...>
    ...>   defp len_by(len), do: len
    ...> end
    ...>
    ...> defmodule WithTakeWhileByStruct do
    ...>   use BinStruct
    ...>
    ...>   register_callback &take_while_by/1, items: :field
    ...>
    ...>   field :items, { :list_of, TakeWhileExampleItem }, take_while_by: &take_while_by/1
    ...>
    ...>   defp take_while_by(items) do
    ...>
    ...>    [ current_item | _previous_items ] = items
    ...>    case TakeWhileExampleItem.decode(current_item) do
    ...>      %{ value: "C" } -> :halt
    ...>      _ -> :cont
    ...>    end
    ...>   end
    ...> end
    ...>
    ...> WithTakeWhileByStruct.new(items: [ TakeWhileExampleItem.new(len: 1, value: "A"), TakeWhileExampleItem.new(len: 1, value: "B"), TakeWhileExampleItem.new(len: 1, value: "C") ])
    ...> |> WithTakeWhileByStruct.dump_binary()
    ...> |> WithTakeWhileByStruct.parse()
    ...> |> then(fn {:ok, struct, _rest } -> struct end)
    ...> |> WithTakeWhileByStruct.decode()
    %{ items: [ TakeWhileExampleItem.new(len: 1, value: "A"), TakeWhileExampleItem.new(len: 1, value: "B"), TakeWhileExampleItem.new(len: 1, value: "C") ] }

```

Now struct can be parsed from infinity bytestream (parse/2 function will be available)

Notice callback takes field itself to which he applied,
which is normally not possible and its unique behaviour of take_while_by callback.

Also notice items are reversed, this is expected to elixir/erlang linked list implementation nature as it more performant
to both produce and to read.

Type conversions are specially optimized for this callback,
type conversion for any item will acquire only once for each item of each type conversion requested


## Future exploring

Most detailed behaviours can be found in test modules in BinStructTest.ListOfTests.*
