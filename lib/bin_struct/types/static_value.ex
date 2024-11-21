defmodule BinStruct.Types.StaticValue do

  @moduledoc """

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

  ## Inline String.t()

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
