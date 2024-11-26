defmodule BinStruct.Macro.Decode.DecodeTopologyNodes.UnmanagedFieldValueNode do

  @moduledoc false

  alias BinStruct.Macro.Decode.DecodeTopologyNodes.UnmanagedFieldValueNode
  alias BinStruct.Macro.Structs.Field

  @type t :: %UnmanagedFieldValueNode {
               field:  Field.t()
             }

  defstruct [
    :field
  ]


end
