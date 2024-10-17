defmodule BinStruct.Macro.Structs.OneOfPack do

  alias BinStruct.Macro.Structs.OneOfPack
  alias BinStruct.Macro.Structs.Field

  @type t :: %OneOfPack {
               fields: list(
                 Field.t()
               )
             }

  defstruct [
    :fields
  ]


end
