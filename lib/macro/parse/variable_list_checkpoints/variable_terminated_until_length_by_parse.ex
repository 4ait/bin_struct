defmodule BinStruct.Macro.Parse.VariableListCheckpoints.VariableTerminatedUntilLengthByParse do

  alias BinStruct.Macro.Parse.ListOfBoundaryConstraintFunctionCall
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Parse.Validation
  alias BinStruct.Macro.Parse.WrapWithOptionalBy
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies
  alias BinStruct.Macro.Dependencies.DeconstructionOfOnOptionDependencies
  alias BinStruct.Macro.Parse.ListItemParseExpressions

  def variable_terminated_until_length_by_parse_checkpoint(
        %{
          item_type: item_type,
          any_length: any_length
        } = _list_of_info,
        %Field{} = field,
        function_name,
        dependencies,
        registered_callbacks_map,
        _env
      ) do


    %Field{ opts: opts } = field

    dependencies_bindings = BindingsToOnFieldDependencies.bindings(dependencies, __MODULE__)

    optional_by = opts[:optional_by]

    parse_until_length_by_parse_function_name = String.to_atom("#{function_name}_until_length_by_parse")

    options_bind = { :options, [], __MODULE__ }
    item_binary_bind = { :item, [], __MODULE__ }
    parse_expr = ListItemParseExpressions.parse_expression(item_type, item_binary_bind, options_bind)

    recursive_parse_functions =

      quote do

        defp unquote(parse_until_length_by_parse_function_name)(<<>>, _options, acc) do
          :lists.reverse(acc)
        end

        defp unquote(parse_until_length_by_parse_function_name)(unquote(item_binary_bind), unquote(options_bind), acc) when is_binary(unquote(item_binary_bind))  do

          case unquote(parse_expr) do

            {:ok, unmanaged_new_item, rest } ->

              new_acc = [ unmanaged_new_item | acc ]

              unquote(parse_until_length_by_parse_function_name)(rest, unquote(options_bind), new_acc)

            :not_enough_bytes -> :not_enough_bytes

            { :wrong_data, _wrong_data } = wrong_data -> wrong_data

          end


        end

      end

    initial_binary_access = { :bin, [], __MODULE__  }

    body =
      quote do

        length =
          unquote(
            ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(
              any_length,
              registered_callbacks_map,
              __MODULE__
            )
          )

        if length >= byte_size(unquote(initial_binary_access)) do

          <<target_bin::size(length)-bytes, rest::binary>> = unquote(initial_binary_access)

          structs = unquote(parse_until_length_by_parse_function_name)(target_bin, options, [])

          { :ok, structs, rest, options }

        else
          :not_enough_bytes
        end

      end

    wrong_data_binary_bind = { :binary_for_wrong_data, [], __MODULE__ }

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, wrong_data_binary_bind, __MODULE__)

    validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, body, __MODULE__)

    checkpoint_function =
      quote do

        defp unquote(function_name)(
               unquote(initial_binary_access),
               unquote_splicing(dependencies_bindings),
               options
             ) when is_binary(unquote(initial_binary_access)) do

          unquote(
            DeconstructionOfOnOptionDependencies.option_dependencies_deconstruction(dependencies, __MODULE__)
          )

          unquote(wrong_data_binary_bind) = unquote(initial_binary_access)

          unquote(
            WrapWithOptionalBy.maybe_wrap_with_optional_by(validate_and_return_clause, optional_by, initial_binary_access, registered_callbacks_map, __MODULE__)
          )

        end

      end

    List.flatten([ checkpoint_function, recursive_parse_functions ])

  end


end
