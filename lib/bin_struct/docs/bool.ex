defmodule BinStruct.Docs.Bool do

  @moduledoc """

    1 byte:

    ```
      defmodule Struct do
        use BinStruct
        field :value, :bool
      end
    ```

    Bits:

    ```
      defmodule Struct do
        use BinStruct
        field :a1, :bool, bits: 1
        field :a2, :bool, bits: 1
        field :a3, :bool, bits: 1
        field :a4, :bool, bits: 1
        field :a5, :bool, bits: 1
        field :a6, :bool, bits: 1
        field :a7, :bool, bits: 1
        field :a8, :bool, bits: 1
      end
    ```

  """

end
