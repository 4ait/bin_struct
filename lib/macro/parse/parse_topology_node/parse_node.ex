defmodule BinStruct.Macro.Parse.ParseTopologyNode.ParseNode do

    alias BinStruct.Macro.Parse.ParseTopologyNode.ParseNode
    alias BinStruct.Macro.Structs.Field

    @type t :: %ParseNode {
                 field: Field.t(),
               }

    defstruct [
      :field
    ]



end
