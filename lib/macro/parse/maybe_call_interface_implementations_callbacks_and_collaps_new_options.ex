defmodule BinStruct.Macro.Parse.MaybeCallInterfaceImplementationCallbacksAndCollapseNewOptions do

  alias BinStruct.Macro.Parse.CallInterfaceImplementationsCallbacks

  def maybe_call_interface_implementations_callbacks([], _registered_callbacks_map, _context) do
    nil
  end

  def maybe_call_interface_implementations_callbacks(interface_implementations_callbacks, registered_callbacks_map, context) do


    options_bind = { :options, [], context }

    interface_implementations_callbacks_calls = CallInterfaceImplementationsCallbacks.call_interface_implementations_callbacks(interface_implementations_callbacks, registered_callbacks_map, context)

    quote do

      new_implemented_options = unquote(interface_implementations_callbacks_calls)
      collapse_options_into_map(unquote(options_bind), new_implemented_options)

    end

  end

end