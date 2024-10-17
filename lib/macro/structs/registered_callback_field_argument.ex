defmodule BinStruct.Macro.Structs.RegisteredCallbackFieldArgument do

  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.Field

  @type t :: %RegisteredCallbackFieldArgument{
                field: Field.t(),
                options: map()
             }


  defstruct [
    :field,
    :options
  ]


end
