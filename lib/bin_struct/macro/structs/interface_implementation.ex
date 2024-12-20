defmodule BinStruct.Macro.Structs.InterfaceImplementation do

  @moduledoc false

  alias BinStruct.Macro.Structs.InterfaceImplementation
  alias BinStruct.Macro.Structs.Callback

  @type t :: %InterfaceImplementation{
               interface: atom(),
               callback: Callback.t()
             }

  defstruct [
    :interface,
    :callback
  ]


end
