defmodule BinStruct.Macro.Parse.CallInterfaceImplementationsCallbacks do

  alias BinStruct.Macro.Structs.InterfaceImplementation
  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap

  def call_interface_implementations_callbacks([], _registered_callbacks_map, _context) do

    quote do
      []
    end

  end

  def call_interface_implementations_callbacks([ %InterfaceImplementation{} = interface_implementation | tail], registered_callbacks_map, context) do

    %InterfaceImplementation{ callback: callback } = interface_implementation

    registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, callback)

    registered_callback_function_call = RegisteredCallbackFunctionCall.registered_callback_function_call(registered_callback, context)

    case tail do
      [] ->
        quote do
          unquote(registered_callback_function_call)
        end

      _tail ->

        quote do
          [
            unquote(registered_callback_function_call) |
            unquote(
              call_interface_implementations_callbacks(tail, registered_callbacks_map, context)
            )
          ]
        end

    end

  end

end