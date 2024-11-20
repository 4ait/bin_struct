defmodule BinStruct.Types.Flags do

  @moduledoc """

  ## Defining struct with flags

    ```
      defmodule FlagsStruct do
        use BinStruct

        field :flags, {
          :flags,
          %{
            type: :uint32_le,
            values: [
              { 0x00000001, :info_mouse },
              { 0x00000002, :info_disablectrlaltdel }
            ]
          }
        }
      end

    ```

  """

end
