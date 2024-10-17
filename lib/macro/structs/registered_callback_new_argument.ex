defmodule BinStruct.Macro.Structs.RegisteredCallbackNewArgument do

  alias BinStruct.Macro.Structs.RegisteredCallbackNewArgument
  alias BinStruct.Macro.Structs.Field

  @type t :: %RegisteredCallbackNewArgument{
                field: Field.t(),
                options: map()
             }

  defstruct [
    :field,
    :options
  ]


end
