defmodule BinStruct.Macro.Parse.CheckpointVariableList do

  alias BinStruct.Macro.Parse.ListOfBoundaryConstraintFunctionCall
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Parse.Validation
  alias BinStruct.Macro.Parse.WrapWithOptionalBy
  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Dependencies.DeconstructionOfOnOptionDependencies
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.Types.TypeConversionBinary
  alias BinStruct.TypeConversion.TypeConversionUnspecified
  alias BinStruct.Macro.Parse.ListItemParseExpressions
  alias BinStruct.Macro.Dependencies.CallbacksDependencies
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies

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

        def unquote(parse_until_length_by_parse_function_name)(<<>>, _options, acc) do
          :lists.reverse(acc)
        end

        def unquote(parse_until_length_by_parse_function_name)(unquote(item_binary_bind), unquote(options_bind), acc) when is_binary(unquote(item_binary_bind))  do

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

  def variable_terminated_until_count_by_parse_checkpoint(
        %{
          item_type: item_type,
          any_count: any_count
        }  = _list_of_info,
        %Field{} = field,
        function_name,
        dependencies,
        registered_callbacks_map,
        _env
      ) do

    dependencies_bindings = BindingsToOnFieldDependencies.bindings(dependencies, __MODULE__)

    %Field{ opts: opts } = field

    optional_by = opts[:optional_by]

    parse_until_count_by_parse_function_name = String.to_atom("#{function_name}_until_count_by_parse")

    options_bind = { :options, [], __MODULE__ }
    item_binary_bind = { :item, [], __MODULE__ }
    parse_expr = ListItemParseExpressions.parse_expression(item_type, item_binary_bind, options_bind)

    recursive_parse_functions =

      quote do

        def unquote(parse_until_count_by_parse_function_name)(rest, _options, _remain = 0, acc) do
          { :lists.reverse(acc), rest }
        end

        def unquote(parse_until_count_by_parse_function_name)(unquote(item_binary_bind), unquote(options_bind), remain, acc) when is_binary(unquote(item_binary_bind)) do

          case unquote(parse_expr) do

            {:ok, unmanaged_new_item, rest } ->

              new_acc = [ unmanaged_new_item | acc ]

              unquote(parse_until_count_by_parse_function_name)(rest, unquote(options_bind), remain - 1, new_acc)

            :not_enough_bytes -> :not_enough_bytes

            { :wrong_data, _wrong_data } = wrong_data -> wrong_data

          end

        end

      end


    initial_binary_access = { :bin, [], __MODULE__  }

    body =
      quote do

        count =
          unquote(
            ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(
              any_count,
              registered_callbacks_map,
              __MODULE__
            )
          )

        { structs, rest } = unquote(parse_until_count_by_parse_function_name)(unquote(initial_binary_access), options, count, [])

        { :ok, structs, rest, options }

      end


    wrong_data_binary_bind = { :binary_for_wrong_data, [], __MODULE__ }

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, wrong_data_binary_bind,  __MODULE__)

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

  def variable_terminated_take_while_by_callback_by_item_size_checkpoint(
        %{
          item_type: item_type,
          any_item_size: any_item_size,
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

    parse_take_while_by_callback_by_item_size_function_name = String.to_atom("#{function_name}_take_while_by_callback_by_item_size")

    take_while_by_registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, take_while_by)

    %{
      has_dependency_on_managed: has_dependency_on_managed,
      has_dependency_on_unspecified: has_dependency_on_unspecified,
      has_dependency_on_unmanaged: _has_dependency_on_unmanaged,
      has_dependency_on_binary: has_dependency_on_binary
    } = take_while_be_dependency_on_self_info(name, take_while_by_registered_callback)

    has_dependency_on_managed = has_dependency_on_managed || has_dependency_on_unspecified

    managed_value_bind = Bind.bind_managed_value(name, __MODULE__)
    unmanaged_value_bind = Bind.bind_unmanaged_value(name, __MODULE__)
    binary_value_bind = Bind.bind_binary_value(name, __MODULE__)

    take_while_by_function_call =
      RegisteredCallbackFunctionCall.registered_callback_function_call(
        take_while_by_registered_callback,
        __MODULE__
      )

    options_bind = { :options, [], __MODULE__ }
    item_binary_bind = { :item, [], __MODULE__ }
    unmanaged_new_item_bind = { :unmanaged_new_item, [], __MODULE__ }

    parse_expr = ListItemParseExpressions.parse_exact_expression(item_type, item_binary_bind, options_bind)

    recursive_parse_functions =

      quote do

        def unquote(parse_take_while_by_callback_by_item_size_function_name)(binary, _options, item_size, _items_with_different_type_conversions_acc)
            when is_integer(item_size) and byte_size(binary) < item_size do
          :not_enough_bytes
        end

        def unquote(parse_take_while_by_callback_by_item_size_function_name)(binary, unquote(options_bind), item_size, items_with_different_type_conversions_acc) when is_binary(binary) do

          <<unquote(item_binary_bind)::size(item_size)-bytes, rest::binary>> = binary

          { unmanaged_items_acc, managed_items_acc, binary_items_acc } = items_with_different_type_conversions_acc

          case unquote(parse_expr) do

            {:ok, unquote(unmanaged_new_item_bind) } ->

              managed_new_item =
                unquote(
                  if has_dependency_on_managed do
                    BinStruct.Macro.TypeConverterToManaged.convert_unmanaged_value_to_managed(item_type, unmanaged_new_item_bind)
                  end
                )

              binary_new_item =
                unquote(
                  if has_dependency_on_binary do

                    quote do
                      <<item_binary_part::binary-size(byte_size(binary) - byte_size(rest)), _rest>> = binary
                      item_binary_part
                    end

                  end
                )

              unquote(unmanaged_value_bind) = [ unquote(unmanaged_new_item_bind) | unmanaged_items_acc ]
              unquote(managed_value_bind) = [ managed_new_item | managed_items_acc ]
              unquote(binary_value_bind) = [ binary_new_item | binary_items_acc ]

              take_while_by_callback_result = unquote(take_while_by_function_call)

              case take_while_by_callback_result do

                :cont ->

                  new_acc = {
                    unquote(unmanaged_value_bind),
                    unquote(managed_value_bind),
                    unquote(binary_value_bind)
                  }

                  unquote(parse_take_while_by_callback_by_item_size_function_name)(rest, unquote(options_bind), item_size, new_acc)

                :halt ->  { :ok, :lists.reverse(unquote(unmanaged_value_bind)), rest }

              end

            { :wrong_data, _wrong_data } = wrong_data -> wrong_data

          end

        end

      end

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

        items_with_different_type_conversions_acc = {  _unmanaged = [], _managed = [], _binary = [] }

        parse_function_call_result = unquote(parse_take_while_by_callback_by_item_size_function_name)(unquote(initial_binary_access), options, item_size,  items_with_different_type_conversions_acc)

        case parse_function_call_result do
          { :ok, items, rest } -> { :ok, items, rest, options }
          :not_enough_bytes -> :not_enough_bytes
        end

      end

    wrong_data_binary_bind = { :binary_for_wrong_data, [], __MODULE__ }

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, wrong_data_binary_bind,  __MODULE__)

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
    } = take_while_be_dependency_on_self_info(name, take_while_by_registered_callback)

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

    recursive_parse_functions =

      quote do

        def unquote(parse_take_while_by_callback_by_parse_function_name)(unquote(item_binary_bind), unquote(options_bind), items_with_different_type_conversions_acc) when is_binary(binary) and is_list(acc) do

          { unmanaged_items_acc, managed_items_acc, binary_items_acc } = items_with_different_type_conversions_acc

          case unquote(parse_expr) do

            {:ok, unquote(unmanaged_new_item_bind), rest } ->

              managed_new_item =
                unquote(
                  if has_dependency_on_managed do
                    BinStruct.Macro.TypeConverterToManaged.convert_unmanaged_value_to_managed(item_type, unmanaged_new_item_bind)
                  end
                )

              binary_new_item =
                unquote(
                  if has_dependency_on_binary do

                    quote do
                      <<item_binary_part::binary-size(unquote(item_binary_bind) - byte_size(rest)), _rest>> = unquote(item_binary_bind)
                      item_binary_part
                    end

                  end
                )

              unquote(unmanaged_value_bind) = [ unquote(unmanaged_new_item_bind) | unmanaged_items_acc ]
              unquote(managed_value_bind) = [ managed_new_item | managed_items_acc ]
              unquote(binary_value_bind) = [ binary_new_item | binary_items_acc ]

              take_while_by_callback_result = unquote(take_while_by_function_call)

              case take_while_by_callback_result do

                :cont ->

                  new_acc = {
                    unquote(unmanaged_value_bind),
                    unquote(managed_value_bind),
                    unquote(binary_value_bind)
                  }

                  unquote(parse_take_while_by_callback_by_parse_function_name)(rest, unquote(options_bind), new_acc)

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

        parse_function_call_result = unquote(parse_take_while_by_callback_by_parse_function_name)(unquote(initial_binary_access), options, items_with_different_type_conversions_acc)

        case parse_function_call_result do
          { :ok, items, rest } -> { :ok, items, rest, options }
          bad_result -> bad_result
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
    parse_expr = ListItemParseExpressions.parse_exact_expression(item_type, item_binary_bind, options_bind)

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

    wrong_data_binary_bind = { :binary_for_wrong_data, [], __MODULE__ }

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, wrong_data_binary_bind, __MODULE__)

    validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, body, __MODULE__)

    quote do

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


  def variable_not_terminated_until_end_by_parse_checkpoint(
        %{
          item_type: item_type,
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

    parse_until_end_by_parse_function_name = String.to_atom("#{function_name}_until_end_by_parse")

    options_bind = { :options, [], __MODULE__ }
    item_binary_bind = { :item, [], __MODULE__ }
    parse_expr = ListItemParseExpressions.parse_expression(item_type, item_binary_bind, options_bind)

    recursive_parse_functions =
      quote do

        def unquote(parse_until_end_by_parse_function_name)(<<>>, _options, acc) do
          { :ok, :lists.reverse(acc) }
        end

        def unquote(parse_until_end_by_parse_function_name)(unquote(item_binary_bind), unquote(options_bind), acc) when is_binary(binary) do

          case unquote(parse_expr) do

            {:ok, unmanaged_new_item, rest } ->

              new_acc = [ unmanaged_new_item | acc ]

              unquote(parse_until_end_by_parse_function_name)(rest, unquote(options_bind), new_acc)

            :not_enough_bytes -> :not_enough_bytes

            { :wrong_data, _wrong_data } = wrong_data -> wrong_data

          end

        end

      end

    initial_binary_access = { :bin, [], __MODULE__  }

    body =
      quote do

        result = unquote(parse_until_end_by_parse_function_name)(unquote(initial_binary_access), options, [])

        case result do
          { :ok, structs } ->  { :ok, structs, "", options }
          bad_result -> bad_result
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

    [ checkpoint_function ] ++ recursive_parse_functions

  end

  defp take_while_be_dependency_on_self_info(current_field_name, take_while_by_registered_callback) do

    take_while_by_dependencies = CallbacksDependencies.dependencies([take_while_by_registered_callback])

    dependency_on_self_items_for_type_conversions =
      Enum.reduce(
        take_while_by_dependencies,
        [],
        fn take_while_by_dependency, acc ->

          case take_while_by_dependency do
            %DependencyOnField{ field: field, type_conversion: type_conversion } ->

              case field do
                %Field{ name: ^current_field_name } -> [ type_conversion | acc ]
                _ -> acc
              end

            _ -> acc

          end

        end
      )

    has_dependency_on_managed =
      Enum.any?(
        dependency_on_self_items_for_type_conversions,
        fn type_conversion -> type_conversion == TypeConversionManaged end
      )

    has_dependency_on_unspecified =
      Enum.any?(
        dependency_on_self_items_for_type_conversions,
        fn type_conversion -> type_conversion == TypeConversionUnspecified end
      )


    has_dependency_on_unmanaged =
      Enum.any?(
        dependency_on_self_items_for_type_conversions,
        fn type_conversion -> type_conversion == TypeConversionUnmanaged end
      )

    has_dependency_on_binary =
      Enum.any?(
        dependency_on_self_items_for_type_conversions,
        fn type_conversion -> type_conversion == TypeConversionBinary end
      )

    %{
      has_dependency_on_managed: has_dependency_on_managed,
      has_dependency_on_unspecified: has_dependency_on_unspecified,
      has_dependency_on_unmanaged: has_dependency_on_unmanaged,
      has_dependency_on_binary: has_dependency_on_binary
    }

  end

end
