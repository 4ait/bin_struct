defmodule BinStruct.Types.Enum do
  @moduledoc """

    Enum can be declared as any internal type.

    Here’s an example:

  ## Integer based

    ```
      defmodule EnumInteger do
        use BinStruct

        field :enum, {
          :enum,
          %{
            type: :uint16_le,
            values: [
              {0x0004, :high_color_4bpp},
              {0x0008, :high_color_8bpp},
              {0x000F, :high_color_15bpp},
              {0x0010, :high_color_16bpp},
              {0x0018, :high_color_24bpp}
            ]
          }
        }
      end
    ```

  ## Binaries based

  ```

      defmodule EnumBinaries do
        use BinStruct

        field :enum_as_binary, {
          :enum,
          %{
            type: :binary,
            values: [
              { "A", :high_color_4bpp },
              { "B", :high_color_8bpp },
              { "C", :high_color_15bpp },
              { "D", :high_color_16bpp },
              { "E", :high_color_24bpp }
            ]
          }
        }
      end

    ```

  """

end