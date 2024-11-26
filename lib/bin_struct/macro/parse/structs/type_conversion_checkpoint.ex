defmodule BinStruct.Macro.Parse.Structs.TypeConversionCheckpoint do

  @moduledoc false

  alias BinStruct.Macro.Parse.Structs.TypeConversionCheckpoint

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
