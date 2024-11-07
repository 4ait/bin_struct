defmodule BinStruct.Macro.Parse.VariableListCheckpoints.VariableNotTerminatedUntilEndByItemSize do

  alias BinStruct.Macro.Parse.ListOfBoundaryConstraintFunctionCall
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Parse.Validation
  alias BinStruct.Macro.Parse.WrapWithOptionalBy
  alias BinStruct.Macro.Dependencies.DeconstructionOfOnOptionDependencies
  alias BinStruct.Macro.Parse.ListItemParseExpressions
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies


  def variable_not_terminated_until_end_by_item_size_checkpoint(
        %{
          item_type: item_type,
          any_item_size: any_item_size
        } = _list_of_info,
        %Field{} = field,
        function_name,
        dependencies,
        registered_callbacks_map,
        _env
      ) do

    dependencies_bindings = BindingsToOnFieldDependencies.bindings(dependencies, __MODULE__)

    %Field{ opts: opts } = field

    optional_by = opts[:optional_by]

    options_bind = { :options, [], __MODULE__ }
    item_binary_bind = { :item, [], __MODULE__ }
    %{ expr: parse_expr, is_infailable_of_primitive_type: is_infailable_of_primitive_type } = ListItemParseExpressions.parse_exact_expression(item_type, item_binary_bind, options_bind)

    initial_binary_access = { :bin, [], __MODULE__  }

    body =
      quote do

        item_size =
          unquote(
            ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(
              any_item_size,
              registered_callbacks_map,
              __MODULE__
            )
          )

        unquote(
          if is_infailable_of_primitive_type do


            quote do

              items =
                for << unquote(item_binary_bind)::binary-size(item_size) <- unquote(initial_binary_access) >> do
                  unquote(parse_expr)
                end

              { :ok, items, "", unquote(options_bind) }

            end

          else


            quote do

              chunks =
                for << chunk::binary-size(item_size) <- unquote(initial_binary_access) >> do
                  chunk
                end

              result =
                Enum.reduce_while(chunks, { :ok, [] }, fn unquote(item_binary_bind), acc ->

                  { _, items } = acc

                  case unquote(parse_expr) do

                    { :ok, unmanaged_item } ->

                      new_items = [ unmanaged_item | items ]

                      { :cont, { :ok, new_items } }

                    bad_result -> { :halt, bad_result }

                  end

                end)


              case result do
                { :ok, items } ->  { :ok, Enum.reverse(items), "", unquote(options_bind) }
                bad_result -> bad_result
              end

            end

          end
        )

      end

    wrong_data_binary_bind = { :binary_for_wrong_data, [], __MODULE__ }

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, wrong_data_binary_bind, __MODULE__)

    validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, body, __MODULE__)

    quote  do

      defp unquote(function_name)(
             unquote(initial_binary_access),
             unquote_splicing(dependencies_bindings),
             options
           ) when is_binary(unquote(initial_binary_access)) do

        unquote(
          DeconstructionOfOnOptionDependencies.option_dependencies_deconstruction(dependencies, __MODULE__)
        )

        unquote(options_bind) = options
        unquote(wrong_data_binary_bind) = unquote(initial_binary_access)

        unquote(
          WrapWithOptionalBy.maybe_wrap_with_optional_by(validate_and_return_clause, optional_by, initial_binary_access, registered_callbacks_map, __MODULE__)
        )

      end

    end


  end


end
