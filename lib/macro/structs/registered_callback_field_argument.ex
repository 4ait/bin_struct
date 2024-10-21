defmodule BinStruct.Macro.Structs.RegisteredCallbackFieldArgument do

  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField

  @type t :: %RegisteredCallbackFieldArgument{
                field: Field.t() | VirtualField.t(),
                options: map()
             }


  defstruct [
    :field,
    :options
  ]


end
