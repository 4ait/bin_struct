defmodule BinStruct.Macro.Structs.OptionsInterfaceImplementationCheckpoint do

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
