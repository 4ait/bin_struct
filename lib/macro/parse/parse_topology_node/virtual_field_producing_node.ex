defmodule BinStruct.Macro.Parse.ParseTopologyNode.VirtualFieldProducingNode do


    alias BinStruct.Macro.Parse.ParseTopologyNode.VirtualFieldProducingNode

    alias BinStruct.Macro.Structs.VirtualField


    @type t :: %VirtualFieldProducingNode {
                 virtual_field: VirtualField.t()
               }

    defstruct [
      :virtual_field
    ]



end
