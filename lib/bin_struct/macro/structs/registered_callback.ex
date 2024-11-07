defmodule BinStruct.Macro.Structs.RegisteredCallback do

  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument

  @type t :: %RegisteredCallback{
               function: any(),
               arguments: list(
                 RegisteredCallbackFieldArgument.t() |
                 RegisteredCallbackOptionArgument.t()
               ),
             }

  defstruct [
    :function,
    :arguments
  ]


end
