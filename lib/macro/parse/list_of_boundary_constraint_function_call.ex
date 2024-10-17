defmodule BinStruct.Macro.Parse.ListOfBoundaryConstraintFunctionCall do

  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  
  def function_call_or_unwrap_value({:runtime, callback}, registered_callbacks_map, context) do

    registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, callback)

    RegisteredCallbackFunctionCall.registered_callback_function_call(registered_callback, context)
  end

  def function_call_or_unwrap_value({:compile_time, value}, _registered_callbacks_map, _context) do
    value
  end

end