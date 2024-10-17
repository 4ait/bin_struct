defmodule BinStruct.Macro.Structs.RegisteredCallback do

  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackItemArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackNewArgument
  alias BinStruct.Macro.Structs.Field

  @type t :: %RegisteredCallback{
               function: any(),
               arguments: list(
                 RegisteredCallbackFieldArgument.t() |
                 RegisteredCallbackOptionArgument.t() |
                 RegisteredCallbackItemArgument.t() |
                 RegisteredCallbackNewArgument.t()
               ),
               returns:
                 :unspecified |
                  list(
                    Field.t()
                 )
             }

  defstruct [
    :function,
    :arguments,
    :returns
  ]


end
