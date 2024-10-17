defmodule BinStruct.Macro.Structs.RegisteredCallbackItemArgument do

  alias BinStruct.Macro.Structs.RegisteredCallbackItemArgument
  alias BinStruct.Macro.Structs.Field

  @type t :: %RegisteredCallbackItemArgument{
                item_of_field: Field.t(),
                options: map()
             }

  defstruct [
    :item_of_field,
    :options
  ]

end
