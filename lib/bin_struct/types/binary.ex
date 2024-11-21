defmodule BinStruct.Types.Binary do

  @moduledoc """

  ## Non terminated:

     ```

      iex> defmodule StructNonTerminated do
      ...>   use BinStruct
      ...>   field :value, :binary
      ...> end
      ...>
      ...> StructNonTerminated.new(value: "123")
      ...> |> StructNonTerminated.dump_binary()
      ...> |> StructNonTerminated.parse_exact()
      ...> |> then(fn {:ok, struct} -> struct end)
      ...> |> StructNonTerminated.decode()
      %{value: "123"}

     ```

  ## Known length:

    ```

      iex> defmodule StructKnownLength do
      ...>   use BinStruct
      ...>   field :value, :binary, length: 3
      ...> end
      ...>
      ...> StructKnownLength.new(value: "123")
      ...> |> StructKnownLength.dump_binary()
      ...> |> StructKnownLength.parse()
      ...> |> then(fn {:ok, struct, _rest} -> struct end)
      ...> |> StructKnownLength.decode()
      %{value: "123"}

    ```

  ##  Dynamic length:


    ```

      iex> defmodule StructWithDynamicLength do
      ...>   use BinStruct
      ...>
      ...>   register_callback &len/0
      ...>   field :value, :binary, length_by: &len/0
      ...>
      ...>   defp len(), do: 3
      ...> end
      ...>
      ...> StructWithDynamicLength.new(value: "123")
      ...> |> StructWithDynamicLength.dump_binary()
      ...> |> StructWithDynamicLength.parse()
      ...> |> then(fn {:ok, struct, _rest} -> struct end)
      ...> |> StructWithDynamicLength.decode()
      %{value: "123"}

    ```

  """

end
