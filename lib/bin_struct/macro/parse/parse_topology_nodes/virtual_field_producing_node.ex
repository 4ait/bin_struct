defmodule BinStruct.Macro.Parse.ParseTopologyNodes.VirtualFieldProducingNode do

  @moduledoc false

  alias BinStruct.Macro.Parse.ParseTopologyNodes.VirtualFieldProducingNode

  alias BinStruct.Macro.Structs.VirtualField


  @type t :: %VirtualFieldProducingNode {
               virtual_field: VirtualField.t()
             }

  defstruct [
    :virtual_field
  ]



end
