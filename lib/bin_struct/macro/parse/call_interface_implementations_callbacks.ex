defmodule BinStruct.Macro.Parse.CallInterfaceImplementationsCallbacks do

  @moduledoc false

  alias BinStruct.Macro.Structs.InterfaceImplementation
  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap

  def call_interface_implementations_callbacks(interface_implementations, registered_callbacks_map, context) do

    interface_implementations_registered_callbacks_calls =
      Enum.map(
        interface_implementations,
        fn interface_implementation ->

          %InterfaceImplementation{ callback: callback } = interface_implementation

          registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, callback)

          RegisteredCallbackFunctionCall.registered_callback_function_call(registered_callback, context)

        end
      )

    quote do
      [ unquote_splicing(interface_implementations_registered_callbacks_calls) ]
    end


  end

end