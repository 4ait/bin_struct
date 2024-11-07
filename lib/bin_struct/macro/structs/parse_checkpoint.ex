defmodule BinStruct.Macro.Structs.ParseCheckpoint do

  alias BinStruct.Macro.Structs.ParseCheckpoint
  alias BinStruct.Macro.Structs.Field

  @type t :: %ParseCheckpoint {
               fields: list(
                 Field.t()
               )
             }

  defstruct [
    :fields
  ]

end
