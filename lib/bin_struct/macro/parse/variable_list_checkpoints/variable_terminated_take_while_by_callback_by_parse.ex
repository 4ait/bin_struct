defmodule BinStruct.Macro.Parse.VariableListCheckpoints.VariableTerminatedTakeWhileByCallbackByParse do

  @moduledoc false

  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Parse.Validation
  alias BinStruct.Macro.Parse.WrapWithOptionalBy
  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Dependencies.DeconstructionOfOnOptionDependencies
  alias BinStruct.Macro.Parse.ListItemParseExpressions
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies
  alias BinStruct.Macro.Dependencies.BindingsToOnOptionDependencies
  alias BinStruct.Macro.TypeConverterToManaged

  alias BinStruct.Macro.Parse.TakeWhileByDependencyOnSelfInfo

  def variable_terminated_take_while_by_callback_by_parse_checkpoint(
        %{
          item_type: item_type,
          take_while_by: take_while_by
        }  = _list_of_info,
        %Field{} = field,
        function_name,
        dependencies,
        registered_callbacks_map,
        _env
      ) do

    dependencies_bindings = BindingsToOnFieldDependencies.bindings(dependencies, __MODULE__)

    %Field{ name: name, opts: opts } = field

    optional_by = opts[:optional_by]

    parse_take_while_by_callback_by_parse_function_name = String.to_atom("#{function_name}_take_while_by_callback_by_parse")

    take_while_by_registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, take_while_by)

    managed_value_bind = Bind.bind_managed_value(name, __MODULE__)
    unmanaged_value_bind = Bind.bind_unmanaged_value(name, __MODULE__)
    binary_value_bind = Bind.bind_binary_value(name, __MODULE__)

    %{
      has_dependency_on_managed: has_dependency_on_managed,
      has_dependency_on_unspecified: has_dependency_on_unspecified,
      has_dependency_on_unmanaged: _has_dependency_on_unmanaged,
      has_dependency_on_binary: has_dependency_on_binary
    } = TakeWhileByDependencyOnSelfInfo.take_while_by_dependency_on_self_info(name, take_while_by_registered_callback)

    has_dependency_on_managed = has_dependency_on_managed || has_dependency_on_unspecified

    take_while_by_function_call =
      RegisteredCallbackFunctionCall.registered_callback_function_call(
        take_while_by_registered_callback,
        __MODULE__
      )

    options_bind = { :options, [], __MODULE__ }
    item_binary_bind = { :item, [], __MODULE__ }
    unmanaged_new_item_bind = { :unmanaged_new_item, [], __MODULE__ }
    parse_expr = ListItemParseExpressions.parse_expression(item_type, item_binary_bind, options_bind)

    inner_function_on_option_dependencies_bindings =
      BindingsToOnOptionDependencies.bindings(
        dependencies,
        __MODULE__
      )

    recursive_parse_functions =

      quote do

        defp unquote(parse_take_while_by_callback_by_parse_function_name)(
               unquote(item_binary_bind),
               unquote_splicing(dependencies_bindings),
               unquote(options_bind),
               unquote_splicing(inner_function_on_option_dependencies_bindings),
               items_with_different_type_conversions_acc
             )
             when is_binary( unquote(item_binary_bind) )

          do

          { unmanaged_items_acc, managed_items_acc, binary_items_acc } = items_with_different_type_conversions_acc

          case unquote(parse_expr) do

            {:ok, unquote(unmanaged_new_item_bind), rest } ->

              unquote(unmanaged_value_bind) = [ unquote(unmanaged_new_item_bind) | unmanaged_items_acc ]

              unquote(managed_value_bind) =

                unquote(
                  if has_dependency_on_managed do

                    quote do

                      managed_new_item =
                        unquote(
                          TypeConverterToManaged.convert_unmanaged_value_to_managed(
                            item_type,
                            unmanaged_new_item_bind
                          )
                        )

                      [ managed_new_item | managed_items_acc ]
                    end

                  else
                    quote do
                      managed_items_acc
                    end
                  end
                )

              unquote(binary_value_bind) =

                unquote(
                  if has_dependency_on_binary do

                    quote do

                      total_length = byte_size(unquote(item_binary_bind))
                      parsed_item_length = total_length - byte_size(rest)

                      <<binary_new_item::binary-size(parsed_item_length), _rest>> = unquote(item_binary_bind)

                      [ binary_new_item | binary_items_acc ]

                    end

                  else
                    quote do
                      binary_items_acc
                    end
                  end
                )

              take_while_by_callback_result = unquote(take_while_by_function_call)

              case take_while_by_callback_result do

                :cont ->

                  new_acc = {
                    unquote(unmanaged_value_bind),
                    unquote(managed_value_bind),
                    unquote(binary_value_bind)
                  }

                  unquote(parse_take_while_by_callback_by_parse_function_name)(
                    rest,
                    unquote_splicing(dependencies_bindings),
                    unquote(options_bind),
                    unquote_splicing(inner_function_on_option_dependencies_bindings),
                    new_acc
                  )

                :halt ->  { :ok, :lists.reverse(unquote(unmanaged_value_bind)), rest }

              end

            :not_enough_bytes -> :not_enough_bytes

            {:wrong_data, _wrong_data} = wrong_data -> wrong_data

          end

        end

      end

    initial_binary_access = { :bin, [], __MODULE__  }

    body =
      quote do

        items_with_different_type_conversions_acc = {  _unmanaged = [], _managed = [], _binary = [] }

        parse_function_call_result =
          unquote(parse_take_while_by_callback_by_parse_function_name)(
            unquote(initial_binary_access),
            unquote_splicing(dependencies_bindings),
            options,
            unquote_splicing(inner_function_on_option_dependencies_bindings),
            items_with_different_type_conversions_acc
          )

        case parse_function_call_result do
          { :ok, items, rest } -> { :ok, items, rest, options }
          :not_enough_bytes -> :not_enough_bytes
          {:wrong_data, _wrong_data} = wrong_data -> wrong_data
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
