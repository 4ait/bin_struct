defmodule BinStruct.Types.Bool do

  @moduledoc """

  ## 1 byte

    ```

      iex> defmodule StructOneByteBool do
      ...>   use BinStruct
      ...>   field :value, :bool
      ...> end
      ...>
      ...> StructOneByteBool.new(value: true)
      ...> |> StructOneByteBool.dump_binary()
      ...> |> StructOneByteBool.parse()
      ...> |> then(fn {:ok, struct, _rest } -> struct end)
      ...> |> StructOneByteBool.decode()
      %{ value: true }

    ```

  ##  Variable bit size

     ```

      iex> defmodule StructVariableBitSize do
      ...>   use BinStruct
      ...>   field :a1, :bool, bits: 1
      ...>   field :a2, :bool, bits: 1
      ...>   field :a3, :bool, bits: 1
      ...>   field :a4, :bool, bits: 1
      ...>   field :a5, :bool, bits: 1
      ...>   field :a6, :bool, bits: 1
      ...>   field :a7, :bool, bits: 1
      ...>   field :a8, :bool, bits: 1
      ...> end
      ...>
      ...> StructVariableBitSize.new(a1: true, a2: true, a3: true, a4: true, a5: true, a6: true, a7: true, a8: true)
      ...> |> StructVariableBitSize.dump_binary()
      ...> |> StructVariableBitSize.parse()
      ...> |> then(fn {:ok, struct, _rest } -> struct end)
      ...> |> StructVariableBitSize.decode()
      %{ a1: true, a2: true, a3: true, a4: true, a5: true, a6: true, a7: true, a8: true }

    ```

  """

end
