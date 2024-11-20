defmodule BinStruct.Macro.Parse.ParseTopologyNodes.ParseNode do

  @moduledoc false

  alias BinStruct.Macro.Parse.ParseTopologyNodes.ParseNode
  alias BinStruct.Macro.Structs.Field

  @type t :: %ParseNode {
               field: Field.t(),
             }

  defstruct [
    :field
  ]


end
