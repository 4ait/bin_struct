defmodule BinStruct.Macro.Structs.VirtualField do

  alias BinStruct.Macro.Structs.VirtualField

  @type t :: %VirtualField {
               name: atom(),
               type: atom() | { atom(), any() },
               opts: keyword()
             }


  defstruct [
    :name,
    :type,
    :opts
  ]


end
