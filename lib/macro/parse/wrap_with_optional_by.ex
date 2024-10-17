defmodule BinStruct.Macro.Parse.WrapWithOptionalBy do

  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap

  def wrap_with_optional_by(
        body_expr,
        optional_by,
        binary_bind,
        %RegisteredCallbacksMap{} = registered_callbacks_map,
        context
      ) do

    optional_by = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, optional_by)

    optional_by_function_call =
        RegisteredCallbackFunctionCall.registered_callback_function_call(optional_by, context)

    options_bind = { :options, [], context }

    quote do

      opt_enabled = unquote(optional_by_function_call)

      if opt_enabled do
        unquote(body_expr)
      else
        { :ok, nil, unquote(binary_bind), unquote(options_bind) }
      end

    end

  end

  def maybe_wrap_with_optional_by(body_expr, _optional_by = nil, _binary_bind, _registered_callbacks_map, _context), do: body_expr

  def maybe_wrap_with_optional_by(body_expr, optional_by, binary_bind, registered_callbacks_map, context),
      do: wrap_with_optional_by(body_expr, optional_by, binary_bind, registered_callbacks_map, context)


end