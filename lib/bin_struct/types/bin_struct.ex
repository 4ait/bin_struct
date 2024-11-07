defmodule BinStruct.Types.BinStruct do

  @moduledoc """

    BinStruct itself is valid type for field, allowing nesting

    Here’s an example:

    ```

      defmodule Child do
        use BinStruct
      end

      defmodule Struct do
        use BinStruct
        field :child, Child
      end
    ```

  """

end
