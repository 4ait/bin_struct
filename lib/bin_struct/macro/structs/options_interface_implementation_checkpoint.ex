defmodule BinStruct.Macro.Structs.OptionsInterfaceImplementationCheckpoint do

  @moduledoc false

  alias BinStruct.Macro.Structs.OptionsInterfaceImplementationCheckpoint
  alias BinStruct.Macro.Structs.InterfaceImplementation

  @type t :: %OptionsInterfaceImplementationCheckpoint {
               interface_implementations: list(
                 InterfaceImplementation.t()
               )
             }

  defstruct [
    :interface_implementations
  ]

end
