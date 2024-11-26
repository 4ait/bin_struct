defmodule BinStruct.Macro.Decode.Steps.DecodeStepOpenUnmanagedValues do

  alias BinStruct.Macro.Decode.Steps.DecodeStepOpenUnmanagedValues

  alias BinStruct.Macro.Structs.Field

  @type t :: %DecodeStepOpenUnmanagedValues {
               fields: Field
             }

  defstruct [
    :fields
  ]

end
