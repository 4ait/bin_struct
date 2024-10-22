defmodule BinStruct.Macro.Parse.Validation do

  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap

  def validate_and_return(validate_fields_with_patterns_and_prelude, return_ok_clause, _context) do

      case validate_fields_with_patterns_and_prelude do

        {  [], _prelude } -> return_ok_clause

        { patterns, nil } ->

          quote do

            with unquote_splicing(patterns) do
              unquote(return_ok_clause)
            end

          end

        { patterns, prelude } ->

          quote do

            unquote(prelude)

            with unquote_splicing(patterns) do
              unquote(return_ok_clause)
            end

          end

      end

  end

  defp is_valid_bind(name, context) do

    { String.to_atom("is_valid_#{name}"), [], context }


  end

  def validate_fields_with_patterns_and_prelude(
        fields,
        %RegisteredCallbacksMap{} = registered_callbacks_map,
        context
      ) do

    validate_by_patterns_and_preludes =
        Enum.map(
          fields,
          fn %Field{} = field ->

            %Field{ name: name, type: type, opts: opts } = field

            binary_value_access = Bind.bind_binary_value(name, context)
            unmanaged_value_access = Bind.bind_unmanaged_value(name, context)

            is_valid_access_field = is_valid_bind(name, context)

            validate_by = opts[:validate_by]

            case type do

              _type when not is_nil(validate_by) ->

                validate_by = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, validate_by)

                validate_by_function_call =
                  RegisteredCallbackFunctionCall.registered_callback_function_call(
                    validate_by,
                    context
                  )

                prelude =
                  quote do
                    unquote(is_valid_access_field) = unquote(validate_by_function_call)
                  end

                pattern =
                  quote do
                    :ok <- (if unquote(is_valid_access_field), do: :ok, else: { :wrong_data, unquote(binary_value_access) })
                  end

                { pattern, prelude }

              _ -> nil

            end

          end
        ) |> Enum.reject(&is_nil/1)


      patterns =
        Enum.map(
          validate_by_patterns_and_preludes,
          fn { pattern, _prelude } ->
            pattern
          end
        )

      preludes =
        Enum.map(
          validate_by_patterns_and_preludes,
          fn { _pattern, prelude } ->
            prelude
          end
        ) |> Enum.reject(&is_nil/1)

      prelude =
        case preludes do

         [] -> nil

         preludes ->

           quote do
             unquote_splicing(preludes)
           end

        end


      { patterns, prelude }

  end


end