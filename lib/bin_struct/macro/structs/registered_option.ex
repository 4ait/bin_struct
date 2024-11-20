defmodule BinStruct.Macro.Structs.RegisteredOption do

  @moduledoc false

  alias BinStruct.Macro.Structs.RegisteredOption

  @type t :: %RegisteredOption{
               name: atom(),
               interface: atom(),
               parameters: keyword()
             }


  defstruct [
    :name,
    :interface,
    :parameters
  ]


end
