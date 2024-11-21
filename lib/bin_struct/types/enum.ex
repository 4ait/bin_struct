defmodule BinStruct.Types.Enum do

  @moduledoc """

    Enum can be declared as any internal type.

    Here’s an example:

  ## Integer based

    ```

      iex> defmodule EnumInteger do
      ...>   use BinStruct
      ...>   field :value, {
      ...>    :enum,
      ...>    %{
      ...>     type: :uint16_le,
      ...>     values: [
      ...>      {0x0004, :high_color_4bpp},
      ...>      {0x0008, :high_color_8bpp}
      ...>     ]
      ...>    }
      ...>  }
      ...> end
      ...>
      ...> EnumInteger.new(value: :high_color_4bpp)
      ...> |> EnumInteger.dump_binary()
      ...> |> EnumInteger.parse()
      ...> |> then(fn {:ok, struct, _rest } -> struct end)
      ...> |> EnumInteger.decode()
      %{ value: :high_color_4bpp }

    ```

  ## Binaries based

  ```

      iex> defmodule EnumBinaries do
      ...>   use BinStruct
      ...>   field :value, {
      ...>    :enum,
      ...>    %{
      ...>     type: :binary,
      ...>     values: [
      ...>      { "A" , :high_color_4bpp},
      ...>      { "B", :high_color_8bpp}
      ...>     ]
      ...>    }
      ...>  }, length: 1
      ...> end
      ...>
      ...> EnumBinaries.new(value: :high_color_4bpp)
      ...> |> EnumBinaries.dump_binary()
      ...> |> EnumBinaries.parse()
      ...> |> then(fn {:ok, struct, _rest } -> struct end)
      ...> |> EnumBinaries.decode()
      %{ value: :high_color_4bpp }

   ```

  """

end