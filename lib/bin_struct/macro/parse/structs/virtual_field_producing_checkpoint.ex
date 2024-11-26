defmodule BinStruct.Macro.Parse.Structs.VirtualFieldProducingCheckpoint do

  @moduledoc false

  alias BinStruct.Macro.Parse.Structs.VirtualFieldProducingCheckpoint
  alias BinStruct.Macro.Structs.VirtualField

  @type t :: %VirtualFieldProducingCheckpoint {
               virtual_fields: list(
                 VirtualField.t()
               )
             }

  defstruct [
    :virtual_fields
  ]

end
