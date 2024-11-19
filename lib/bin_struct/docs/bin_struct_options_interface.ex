defmodule BinStruct.Docs.BinStructOptionsInterface do

  @moduledoc """

  ## Basic Example

    ```

      defmodule SharedOptions do

        use BinStructOptionsInterface

        @type runtime_context :: :context_a | :context_b

        register_option :runtime_context

      end

    ```

  """

end
