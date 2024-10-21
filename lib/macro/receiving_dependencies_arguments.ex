defmodule BinStruct.Macro.ReceivingDependenciesArguments do


  alias BinStruct.Macro.CallbacksDependencies
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.Bind

  def receiving_dependencies_arguments(registered_callbacks) do
     CallbacksDependencies.dependencies(registered_callbacks)
  end


end