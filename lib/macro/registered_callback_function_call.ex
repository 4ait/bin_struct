defmodule BinStruct.Macro.RegisteredCallbackFunctionCall do

  alias BinStruct.Macro.FunctionCall

  alias BinStruct.Macro.Structs.RegisteredCallback

  alias BinStruct.Macro.RegisteredCallbackArgumentsBinding

  def registered_callback_function_call(
        %RegisteredCallback{ function: callback_function } = registered_callbacks,
        how_to_treat_unspecified_type_conversions,
        context
      ) do

    arguments_binding =
      RegisteredCallbackArgumentsBinding.registered_callback_arguments_bindings(
        registered_callbacks,
        how_to_treat_unspecified_type_conversions,
        context
      )

    FunctionCall.function_call(callback_function, arguments_binding)

  end

end