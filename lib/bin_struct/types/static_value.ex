defmodule BinStruct.Types.StaticValue do

  @moduledoc """


  Static values are useful in case of clear declaration and validation in general
  but super useful for dispatching variants dynamically. This behaviour will be explained more detail in variant_of docs section.

  You don't need to pass static values when creating new struct and they are validated upon parsing.
  Static values are not stored in any way but always inlined instead.

  ## Inline bytes

    ```

      iex> defmodule StructInlineBytes do
      ...>   use BinStruct
      ...>   field :value, <<1, 2, 3>>
      ...> end
      ...>
      ...> StructInlineBytes.new()
      ...> |> StructInlineBytes.dump_binary()
      ...> |> StructInlineBytes.parse()
      ...> |> then(fn {:ok, struct, _rest } -> struct end)
      ...> |> StructInlineBytes.decode()
      %{ value: <<1, 2, 3>> }

    ```

  ## Optional

    ```

      iex> defmodule StructOptionalStaticValueNotPresent do
      ...>   use BinStruct
      ...>   field :value, <<1, 2, 3>>, optional: true
      ...> end
      ...>
      ...> StructOptionalStaticValueNotPresent.new()
      ...> |> StructOptionalStaticValueNotPresent.dump_binary()
      ...> |> StructOptionalStaticValueNotPresent.parse_exact()
      ...> |> then(fn {:ok, struct } -> struct end)
      ...> |> StructOptionalStaticValueNotPresent.decode()
      %{ value: nil }

      iex> defmodule StructOptionalStaticValuePresent do
      ...>   use BinStruct
      ...>   field :value, <<1, 2, 3>>, optional: true
      ...> end
      ...>
      ...> StructOptionalStaticValuePresent.new(value: :present)
      ...> |> StructOptionalStaticValuePresent.dump_binary()
      ...> |> StructOptionalStaticValuePresent.parse_exact()
      ...> |> then(fn {:ok, struct } -> struct end)
      ...> |> StructOptionalStaticValuePresent.decode()
      %{ value: <<1, 2, 3>> }

    ```

  ## Inline bitstring

    ```

      iex> defmodule StructInlineBitstring do
      ...>   use BinStruct
      ...>   field :first, <<1::1, 1::1, 1::1, 1::1>>
      ...>   field :second, <<0::1, 0::1, 0::1, 0::1>>
      ...> end
      ...>
      ...> StructInlineBitstring.new()
      ...> |> StructInlineBitstring.dump_binary()
      ...> |> StructInlineBitstring.parse()
      ...> |> then(fn {:ok, struct, _rest } -> struct end)
      ...> |> StructInlineBitstring.decode()
      %{ first: <<1::1, 1::1, 1::1, 1::1>>, second: <<0::1, 0::1, 0::1, 0::1>> }

    ```

  ## Inline String.t

    ```

      iex> defmodule StructInlineString do
      ...>   use BinStruct
      ...>   field :value, "123"
      ...> end
      ...>
      ...> StructInlineString.new()
      ...> |> StructInlineString.dump_binary()
      ...> |> StructInlineString.parse()
      ...> |> then(fn {:ok, struct, _rest } -> struct end)
      ...> |> StructInlineString.decode()
      %{ value: "123" }

    ```

  ## Evaluated

    ```

      iex> defmodule StructWithEvaluatedStaticValue do
      ...>   use BinStruct
      ...>
      ...>   @my_static_constant <<1, 2, 3>>
      ...>
      ...>   field :v1, { :static, @my_static_constant }
      ...>   field :v2, { :static, BinStruct.PrimitiveEncoder.uint8(1) }
      ...>
      ...> end
      ...>
      ...> StructWithEvaluatedStaticValue.new()
      ...> |> StructWithEvaluatedStaticValue.dump_binary()
      ...> |> StructWithEvaluatedStaticValue.parse()
      ...> |> then(fn {:ok, struct, _rest } -> struct end)
      ...> |> StructWithEvaluatedStaticValue.decode()
      %{ v1: <<1, 2, 3>>, v2: <<1>> }

    ```

  """



end
