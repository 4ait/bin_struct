defmodule BinStruct.Macro.Dependencies.InterfaceImplementationDependencies do


  alias BinStruct.Macro.Dependencies.CallbacksDependencies
  alias BinStruct.Macro.Dependencies.UniqueDeps
  alias BinStruct.Macro.Structs.InterfaceImplementation

  alias BinStruct.Macro.Structs.RegisteredCallbacksMap


  def interface_implementations_dependencies(interface_implementations, registered_callbacks_map) do

    interface_implementations_callbacks =
      Enum.map(
        interface_implementations,
        fn %InterfaceImplementation{callback: callback} ->
          RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, callback)
        end
      )

    CallbacksDependencies.dependencies(interface_implementations_callbacks)
    |> UniqueDeps.unique_dependencies()

  end

end
