defmodule BinStruct.Macro.Parse.ParseTopologyNodes.InterfaceImplementationNode do

  @moduledoc false

  alias BinStruct.Macro.Parse.ParseTopologyNodes.InterfaceImplementationNode
  alias BinStruct.Macro.Structs.InterfaceImplementation

  @type t :: %InterfaceImplementationNode {
               interface_implementation: InterfaceImplementation.t()
             }

  defstruct [
    :interface_implementation
  ]

end
