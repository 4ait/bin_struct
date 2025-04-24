defmodule BinStruct.Macro.Structs.InterfaceImplementation do

  @moduledoc false

  alias BinStruct.Macro.Structs.InterfaceImplementation
  alias BinStruct.Macro.Structs.Callback

  @type t :: %InterfaceImplementation{
               interface: atom(),
               callback: Callback.t(),
               force_call_before_parse_field_names: list(atom())
             }

  defstruct [
    :interface,
    :callback,
    :force_call_before_parse_field_names
  ]


end
