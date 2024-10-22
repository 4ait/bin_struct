defmodule BinStruct.Macro.RegisteredCallbackFunctionCall do

  alias BinStruct.Macro.FunctionCall

  alias BinStruct.Macro.Structs.RegisteredCallback

  alias BinStruct.Macro.RegisteredCallbackArgumentsBinding
  alias BinStruct.Macro.Structs.UnspecifiedAsManaged

  def registered_callback_function_call(
        %RegisteredCallback{ function: callback_function } = registered_callbacks,
        context
      ) do

    arguments_binding =
      RegisteredCallbackArgumentsBinding.registered_callback_arguments_bindings(
        registered_callbacks,
        %UnspecifiedAsManaged{},
        context
      )

    FunctionCall.function_call(callback_function, arguments_binding)

  end

end