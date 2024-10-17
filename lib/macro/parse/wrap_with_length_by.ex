defmodule BinStruct.Macro.Parse.WrapWithLengthBy do

  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap

  def wrap_with_length_by(
        body_expr,
        length_by,
        binary_bind,
        %RegisteredCallbacksMap{} = registered_callbacks_map,
        context
      ) do

    rest_bind = { :rest, [], context }

    length_by = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, length_by)

    length_by_function_call =
      RegisteredCallbackFunctionCall.registered_callback_function_call(length_by, context)

    quote do

      length = unquote(length_by_function_call)

      case length do

        length when is_integer(length) ->

          if byte_size(unquote(binary_bind)) >= length do

            <<unquote(binary_bind)::size(length)-bytes, unquote(rest_bind)::binary>> = unquote(binary_bind)

            unquote(body_expr)

          else
            :not_enough_bytes
          end

        value -> raise "Non integer value returned from length_by function. Value: #{inspect value}"

      end

    end

  end


end