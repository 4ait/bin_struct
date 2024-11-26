defmodule BinStruct.Macro.Parse.Structs.ParseCheckpoint do

  @moduledoc false

  alias BinStruct.Macro.Parse.Structs.ParseCheckpoint
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
