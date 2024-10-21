defmodule BinStruct.Macro.Structs.DependencyOnOption do

  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.RegisteredOption

  @type t :: %DependencyOnOption {
               option: RegisteredOption.t()
             }

  defstruct [
    :option
  ]


end
