defmodule BinStruct.Macro.Structs.TypeConversionCheckpoint do


  alias BinStruct.Macro.Structs.TypeConversionCheckpoint

  alias BinStruct.Macro.Parse.ParseTopologyNodes.TypeConversionNode

  @type t :: %TypeConversionCheckpoint {
               type_conversion_nodes: list(
                 TypeConversionNode.t()
               )
             }

  defstruct [
    :type_conversion_nodes
  ]

end
