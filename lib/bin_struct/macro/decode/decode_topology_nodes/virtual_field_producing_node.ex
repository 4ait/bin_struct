defmodule BinStruct.Macro.Decode.DecodeTopologyNodes.VirtualFieldProducingNode do

  @moduledoc false

  alias BinStruct.Macro.Decode.DecodeTopologyNodes.VirtualFieldProducingNode

  alias BinStruct.Macro.Structs.VirtualField

  @type t :: %VirtualFieldProducingNode {
               virtual_field: VirtualField.t()
             }

  defstruct [
    :virtual_field
  ]



end
