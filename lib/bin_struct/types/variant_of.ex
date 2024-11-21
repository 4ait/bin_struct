defmodule BinStruct.Types.VariantOf do

  @moduledoc """

  VariantOf is way to select from two or more variants in runtime.


  Dispatching using 2 source of tools:

    1. Performing dynamic variant dispatching using static values as source of determination validness at first place
    2. More complex dispatching available through dynamic callback named validate_by

  BinStruct will select first valid matching variant out of list. In case none is currently can be selected and
  there is not_enough_bytes to check next it will return not_enough_bytes


  ## Static dispatch

    ```

      iex> defmodule VariantA do
      ...>   use BinStruct
      ...>   field :magic_value, <<1>>
      ...> end
      ...>
      ...> defmodule VariantB do
      ...>   use BinStruct
      ...>   field :magic_value, <<2>>
      ...> end
      ...>
      ...> defmodule StructWithStaticVariants do
      ...>   use BinStruct
      ...>   field :one_of_other, { :variant_of, [ VariantA, VariantB ] }
      ...> end
      ...>
      ...> StructWithStaticVariants.new(one_of_other: VariantB.new())
      ...> |> StructWithStaticVariants.dump_binary()
      ...> |> StructWithStaticVariants.parse()
      ...> |> then(fn {:ok, struct, _rest } -> struct end)
      ...> |> StructWithStaticVariants.decode()
      %{ one_of_other: VariantB.new() }

    ```

  ## Dynamic dispatch

    ```

      iex> defmodule VariantAbc do
      ...>   use BinStruct
      ...>
      ...>   register_callback &is_abc_string/1, value: :field
      ...>
      ...>   field :value, :binary,
      ...>      validate_by: &is_abc_string/1,
      ...>      length: 3,
      ...>      default: "abc"
      ...>
      ...>   defp is_abc_string("abc"), do: true
      ...>   defp is_abc_string(_), do: false
      ...>
      ...> end
      ...>
      ...> defmodule VariantCba do
      ...>   use BinStruct
      ...>
      ...>   register_callback &is_cba_string/1, value: :field
      ...>
      ...>   field :value, :binary,
      ...>      validate_by: &is_cba_string/1,
      ...>      length: 3,
      ...>      default: "cba"
      ...>
      ...>   defp is_cba_string("cba"), do: true
      ...>   defp is_cba_string(_), do: false
      ...>
      ...> end
      ...>
      ...> defmodule StructWithDynamicVariants do
      ...>   use BinStruct
      ...>   field :one_of_other, { :variant_of, [ VariantAbc, VariantCba ] }
      ...> end
      ...>
      ...> StructWithDynamicVariants.new(one_of_other: VariantCba.new())
      ...> |> StructWithDynamicVariants.dump_binary()
      ...> |> StructWithDynamicVariants.parse()
      ...> |> then(fn {:ok, struct, _rest } -> struct end)
      ...> |> StructWithDynamicVariants.decode()
      %{ one_of_other: VariantCba.new() }

    ```

  """

end
