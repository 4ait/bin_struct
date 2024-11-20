defmodule BinStruct.Docs.Binary do

  @moduledoc """

    Non terminated:

    ```
      defmodule Struct do
        use BinStruct
        field :value, :binary
      end
    ```

    Known length:

    ```
      defmodule Struct do
        use BinStruct
        field :value, :binary, length: 10
      end
    ```

    Dynamic length:

    ```
      defmodule Struct do

        use BinStruct

        register_callback &len/0

        field :value, :binary, length_by: &len/0

        defp len(), do: 10

      end
    ```

  """

end
