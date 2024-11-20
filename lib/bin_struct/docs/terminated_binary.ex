defmodule BinStruct.Docs.TerminatedBinary do

  @moduledoc """


  Terminated binary implemented as BinStructCustomType.

   ```
      defmodule Struct do
        use BinStruct

        alias BinStruct.BuiltIn.TerminatedBinary

        field :terminated_binary, { TerminatedBinary, termination: <<0, 0>> }
      end
    ```
  """

end
