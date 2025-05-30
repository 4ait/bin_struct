defmodule BinStruct.Macro.Structs.Field do

  @moduledoc false

  alias BinStruct.Macro.Structs.Field

  @type t :: %Field {
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
