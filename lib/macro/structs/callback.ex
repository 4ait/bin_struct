defmodule BinStruct.Macro.Structs.Callback do


  alias BinStruct.Macro.Structs.Callback

  @type t :: %Callback {
               function: any(),
               function_name: String.t(),
               function_arity: integer()
             }

  defstruct [
    :function,
    :function_name,
    :function_arity
  ]

end
