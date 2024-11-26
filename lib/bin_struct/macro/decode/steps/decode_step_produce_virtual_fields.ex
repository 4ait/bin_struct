defmodule BinStruct.Macro.Decode.Steps.DecodeStepProduceVirtualFields do


  alias BinStruct.Macro.Decode.Steps.DecodeStepProduceVirtualFields

  alias BinStruct.Macro.Structs.VirtualField

  @type t :: %DecodeStepProduceVirtualFields {
               virtual_fields: list(
                 VirtualField.t()
               )
             }

  defstruct [
    :virtual_fields
  ]

end
