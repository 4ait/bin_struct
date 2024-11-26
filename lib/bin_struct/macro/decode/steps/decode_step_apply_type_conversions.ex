defmodule BinStruct.Macro.Decode.Steps.DecodeStepApplyTypeConversions do

  @moduledoc false

  alias BinStruct.Macro.Decode.Steps.DecodeStepApplyTypeConversions
  alias BinStruct.Macro.Decode.DecodeTopologyNodes.TypeConversionNode

  @type t :: %DecodeStepApplyTypeConversions {
               type_conversion_nodes: list(
                 TypeConversionNode.t()
               )
             }

  defstruct [
    :type_conversion_nodes
  ]

end
