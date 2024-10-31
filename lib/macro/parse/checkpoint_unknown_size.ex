defmodule BinStruct.Macro.Parse.CheckpointUnknownSize do

  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Parse.Validation
  alias BinStruct.Macro.Parse.Result
  alias BinStruct.Macro.Parse.WrapWithLengthBy
  alias BinStruct.Macro.Parse.WrapWithOptionalBy
  alias BinStruct.Macro.Termination
  alias BinStruct.Macro.Dependencies.DeconstructionOfOnOptionDependencies
  alias BinStruct.Macro.Parse.CheckpointRuntimeBoundedList

  alias BinStruct.Macro.Dependencies.ParseDependencies
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies


  alias BinStruct.Macro.Parse.VariableListCheckpoints.VariableTerminatedUntilLengthByParse
  alias BinStruct.Macro.Parse.VariableListCheckpoints.VariableTerminatedUntilCountByParse
  alias BinStruct.Macro.Parse.VariableListCheckpoints.VariableTerminatedTakeWhileByCallbackByItemSize
  alias BinStruct.Macro.Parse.VariableListCheckpoints.VariableTerminatedTakeWhileByCallbackByParse
  alias BinStruct.Macro.Parse.VariableListCheckpoints.VariableNotTerminatedUntilEndByItemSize
  alias BinStruct.Macro.Parse.VariableListCheckpoints.VariableNotTerminatedUntilEndByParse

  alias BinStruct.Macro.Structs.Field

  def checkpoint_unknown_size([ field ] = _checkpoint, function_name, registered_callbacks_map, env) do

    %Field{ name: name, type: type, opts: opts } = field

    length_by = opts[:length_by]
    optional_by = opts[:optional_by]

    binary_value_access_bind = Bind.bind_binary_value(name, __MODULE__)
    unmanaged_value_access = Bind.bind_unmanaged_value(name, __MODULE__)

    dependencies = ParseDependencies.parse_dependencies_excluded_self([field], registered_callbacks_map)
    dependencies_bindings = BindingsToOnFieldDependencies.bindings(dependencies, __MODULE__)


    case type do

      { :list_of, list_of_info } ->

        case list_of_info do

          %{ type: :runtime_bounded } = list_of_info ->

            CheckpointRuntimeBoundedList.runtime_bounded_list_checkpoint(
              list_of_info,
              field,
              function_name,
              dependencies,
              registered_callbacks_map,
              env
            )

          %{
            type: :variable,
            termination: :terminated,
            take: :until_length_by_parse
          } = list_of_info ->

            VariableTerminatedUntilLengthByParse.variable_terminated_until_length_by_parse_checkpoint(
               list_of_info,
               field,
               function_name,
               dependencies,
               registered_callbacks_map,
               env
            )

          %{
            type: :variable,
            termination: :terminated,
            take: :until_count_by_parse
          } = list_of_info ->

            VariableTerminatedUntilCountByParse.variable_terminated_until_count_by_parse_checkpoint(
              list_of_info,
              field,
              function_name,
              dependencies,
              registered_callbacks_map,
              env
            )

          %{
            type: :variable,
            termination: :terminated,
            take: :take_while_by_callback_by_item_size
          } = list_of_info ->

            VariableTerminatedTakeWhileByCallbackByItemSize.variable_terminated_take_while_by_callback_by_item_size_checkpoint(
              list_of_info,
              field,
              function_name,
              dependencies,
              registered_callbacks_map,
              env
            )

          %{
            type: :variable,
            termination: :terminated,
            take: :take_while_by_callback_by_parse
          } = list_of_info ->

            VariableTerminatedTakeWhileByCallbackByParse.variable_terminated_take_while_by_callback_by_parse_checkpoint(
              list_of_info,
              field,
              function_name,
              dependencies,
              registered_callbacks_map,
              env
            )

          %{
            type: :variable,
            termination: :not_terminated,
            take: :until_end_by_item_size
          } = list_of_info ->

            VariableNotTerminatedUntilEndByItemSize.variable_not_terminated_until_end_by_item_size_checkpoint(
              list_of_info,
              field,
              function_name,
              dependencies,
              registered_callbacks_map,
              env
            )

          %{
            type: :variable,
            termination: :not_terminated,
            take: :until_end_by_parse
          } = list_of_info ->

            VariableNotTerminatedUntilEndByParse.variable_not_terminated_until_end_by_parse_checkpoint(
              list_of_info,
              field,
              function_name,
              dependencies,
              registered_callbacks_map,
              env
            )

        end

      { :variant_of, _variants } = variant_of ->

        case variant_of do

          { :variant_of, variants } when not is_nil(length_by)  ->

            with_patterns_variants_parsing =
              Enum.map(
                variants,
                fn variant ->

                  {:module, module_info } = variant

                  parse_exact_expr =
                    case module_info do

                      %{ module_type: :bin_struct, module: module } ->

                        quote do
                          unquote(module).parse_exact_returning_options(unquote(binary_value_access_bind), options)
                        end

                      %{
                        module_type: :bin_struct_custom_type,
                        module: module,
                        custom_type_args: custom_type_args
                      } ->

                        quote do
                          unquote(module).parse_exact_returning_options(unquote(binary_value_access_bind), unquote(custom_type_args), options)
                        end

                    end

                  quote do
                    { :no_match, _reason, not_enough_bytes_seen } <-

                      (

                        case unquote(parse_exact_expr) do
                          { :ok, _variant, _options } = ok_result ->  ok_result
                          :not_enough_bytes -> { :no_match, :not_enough_bytes, _not_enough_bytes_seen = true }
                          { :wrong_data, _wrong_data } = wrong_data -> { :no_match, wrong_data, not_enough_bytes_seen }
                        end
                        )

                  end


                end
              )

            ok_clause = Result.return_ok_tuple([field], __MODULE__)

            wrong_data_binary_bind = { :binary_for_wrong_data, [], __MODULE__ }

            validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, wrong_data_binary_bind, __MODULE__)

            validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, ok_clause, __MODULE__)


            body =
              quote do

                not_enough_bytes_seen = false

                result =
                  with unquote_splicing(with_patterns_variants_parsing) do

                    case not_enough_bytes_seen do
                      true -> :not_enough_bytes
                      false ->  { :wrong_data, unquote(binary_value_access_bind) }
                    end

                  end

                case result do
                  {:ok, unquote(unmanaged_value_access), options } -> unquote(validate_and_return_clause)
                  { :wrong_data, _wrong_data } = wrong_data_clause -> wrong_data_clause
                  :not_enough_bytes -> :not_enough_bytes
                end

              end

            quote do

              defp unquote(function_name)(
                     unquote(binary_value_access_bind),
                     unquote_splicing(dependencies_bindings),
                     options
                   ) when is_binary(unquote(binary_value_access_bind)) do

                unquote(
                  DeconstructionOfOnOptionDependencies.option_dependencies_deconstruction(dependencies, __MODULE__)
                )

                unquote(wrong_data_binary_bind) = unquote(binary_value_access_bind)

                unquote(
                  WrapWithLengthBy.wrap_with_length_by(body, length_by, binary_value_access_bind, registered_callbacks_map, __MODULE__)
                  |> WrapWithOptionalBy.maybe_wrap_with_optional_by(optional_by, binary_value_access_bind, registered_callbacks_map, __MODULE__)
                )
              end

            end

          { :variant_of, variants }  ->

            with_patterns_variants_parsing =
              Enum.map(
                variants,
                fn variant ->

                  {:module, module_info } = variant

                  is_child_variant_bin_struct_terminated = Termination.is_module_terminated(module_info)

                  case variant do
                    _variant when is_child_variant_bin_struct_terminated ->

                      parse_expr =
                        case module_info do

                          %{ module_type: :bin_struct, module: module } ->
                            quote do
                              unquote(module).parse_returning_options(unquote(binary_value_access_bind), options)
                            end

                          %{
                            module_type: :bin_struct_custom_type,
                            module: module,
                            custom_type_args: custom_type_args
                          } ->
                            quote do
                              unquote(module).parse_returning_options(unquote(binary_value_access_bind), unquote(custom_type_args), options)
                            end
                        end

                      quote do
                        { :no_match, _reason, not_enough_bytes_seen } <-

                            case unquote(parse_expr) do
                              { :ok, _variant, _options, _rest } = ok_result ->  ok_result
                              :not_enough_bytes -> { :no_match, :not_enough_bytes, _not_enough_bytes_seen = true }
                              { :wrong_data, _wrong_data } = wrong_data -> { :no_match, wrong_data, not_enough_bytes_seen }
                            end

                      end

                    {:module, %{module_full_name: module_full_name }} ->

                      message = """
                        BinStruct: #{inspect(module_full_name)} does not have required constraints to be used as variant of :variant_of.
                        All variants should be either self-terminated or length_by should be set for whole set.
                      """

                      raise message

                  end

                end
              )

            ok_clause = Result.return_ok_tuple([field], __MODULE__)

            wrong_data_binary_bind = { :binary_for_wrong_data, [], __MODULE__ }

            validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, wrong_data_binary_bind, __MODULE__)

            validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, ok_clause, __MODULE__)

            body =
              quote do

                not_enough_bytes_seen = false

                result =
                  with unquote_splicing(with_patterns_variants_parsing) do

                    case not_enough_bytes_seen do
                      true -> :not_enough_bytes
                      false ->  { :wrong_data, unquote(binary_value_access_bind) }
                    end

                  end

                case result do
                  { :ok, unquote(unmanaged_value_access), rest, options } -> unquote(validate_and_return_clause)
                  { :wrong_data, _wrong_data } = wrong_data_clause -> wrong_data_clause
                  :not_enough_bytes -> :not_enough_bytes
                end

              end

            quote do

              defp unquote(function_name)(
                     unquote(binary_value_access_bind),
                     unquote_splicing(dependencies_bindings),
                     options
                   ) when is_binary(unquote(binary_value_access_bind)) do

                unquote(
                  DeconstructionOfOnOptionDependencies.option_dependencies_deconstruction(dependencies, __MODULE__)
                )

                unquote(wrong_data_binary_bind) = unquote(binary_value_access_bind)

                unquote(
                  WrapWithOptionalBy.maybe_wrap_with_optional_by(body, optional_by, binary_value_access_bind, registered_callbacks_map, __MODULE__)
                )

              end

            end

        end

      {:module, module_info } ->

        is_child_module_terminated = BinStruct.Macro.Termination.is_module_terminated(module_info)

        case module_info do

          _module_info when not is_nil(length_by) ->

            parse_exact_expr =
              case module_info do

                %{ module_type: :bin_struct, module: module } ->

                  quote do
                    unquote(module).parse_exact_returning_options(unquote(binary_value_access_bind), options)
                  end

                %{
                  module_type: :bin_struct_custom_type,
                  module: module,
                  custom_type_args: custom_type_args
                } ->

                  quote do
                    unquote(module).parse_exact_returning_options(unquote(binary_value_access_bind), unquote(custom_type_args), options)
                  end

              end

            ok_clause =

              quote do

                case unquote(parse_exact_expr) do
                  { :ok, unquote(unmanaged_value_access), options } -> unquote(Result.return_ok_tuple([field], __MODULE__))
                  { :wrong_data, _wrong_data } = wrong_data -> wrong_data
                end

              end

            wrong_data_binary_bind = { :binary_for_wrong_data, [], __MODULE__ }

            validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, wrong_data_binary_bind, __MODULE__)

            validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, ok_clause, __MODULE__)

            quote do

              defp unquote(function_name)(
                     unquote(binary_value_access_bind),
                     unquote_splicing(dependencies_bindings),
                     options
                   ) when is_binary(unquote(binary_value_access_bind)) do

                unquote(
                  DeconstructionOfOnOptionDependencies.option_dependencies_deconstruction(dependencies, __MODULE__)
                )

                unquote(wrong_data_binary_bind) = unquote(binary_value_access_bind)

                unquote(
                  WrapWithLengthBy.wrap_with_length_by(validate_and_return_clause, length_by, binary_value_access_bind, registered_callbacks_map, __MODULE__)
                  |> WrapWithOptionalBy.maybe_wrap_with_optional_by(optional_by, binary_value_access_bind, registered_callbacks_map, __MODULE__)
                )

              end

            end

          _module_info when not is_child_module_terminated ->


            parse_exact_expr =
              case module_info do

                %{ module_type: :bin_struct, module: module } ->

                  quote do
                    unquote(module).parse_exact_returning_options(unquote(binary_value_access_bind), options)
                  end

                %{
                  module_type: :bin_struct_custom_type,
                  module: module,
                  custom_type_args: custom_type_args
                } ->

                  quote do
                    unquote(module).parse_exact_returning_options(unquote(binary_value_access_bind), unquote(custom_type_args), options)
                  end

              end

            ok_clause =

              quote do

                case unquote(parse_exact_expr) do
                  { :ok, unquote(unmanaged_value_access), options } ->
                    rest = ""
                    unquote(Result.return_ok_tuple([field], __MODULE__))
                  { :wrong_data, _wrong_data } = wrong_data -> wrong_data
                end

              end

            wrong_data_binary_bind = { :binary_for_wrong_data, [], __MODULE__ }

            validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, wrong_data_binary_bind, __MODULE__)

            validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, ok_clause, __MODULE__)

            quote do

              defp unquote(function_name)(
                     unquote(binary_value_access_bind),
                     unquote_splicing(dependencies_bindings),
                     options
                   ) when is_binary(unquote(binary_value_access_bind)) do

                unquote(
                  DeconstructionOfOnOptionDependencies.option_dependencies_deconstruction(dependencies, __MODULE__)
                )

                unquote(wrong_data_binary_bind) = unquote(binary_value_access_bind)

                unquote(
                  WrapWithOptionalBy.maybe_wrap_with_optional_by(
                    validate_and_return_clause,
                    optional_by,
                    binary_value_access_bind,
                    registered_callbacks_map,
                    __MODULE__
                  )
                )

              end

            end

          _module_type when is_child_module_terminated ->

            ok_clause = Result.return_ok_tuple([field], __MODULE__)

            wrong_data_binary_bind = { :binary_for_wrong_data, [], __MODULE__ }

            validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, wrong_data_binary_bind, __MODULE__)

            validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, ok_clause, __MODULE__)

            parse_expr =
              case module_info do

                %{ module_type: :bin_struct, module: module } ->

                  quote do
                    unquote(module).parse_returning_options(unquote(binary_value_access_bind), options)
                  end

                %{
                  module_type: :bin_struct_custom_type,
                  module: module,
                  custom_type_args: custom_type_args
                } ->
                  quote do
                    unquote(module).parse_returning_options(unquote(binary_value_access_bind), unquote(custom_type_args), options)
                  end
              end

            body =
              quote do

                case unquote(parse_expr) do

                  { :ok, unquote(unmanaged_value_access), rest, options } -> unquote(validate_and_return_clause)
                  { :wrong_data, _wrong_data } = wrong_data_clause -> wrong_data_clause
                  :not_enough_bytes -> :not_enough_bytes

                end

              end

            quote do

              defp unquote(function_name)(
                     unquote(binary_value_access_bind),
                     unquote_splicing(dependencies_bindings),
                     options
                   ) when is_binary(unquote(binary_value_access_bind)) do

                unquote(
                  DeconstructionOfOnOptionDependencies.option_dependencies_deconstruction(dependencies, __MODULE__)
                )

                unquote(wrong_data_binary_bind) = unquote(binary_value_access_bind)

                unquote(
                  WrapWithOptionalBy.maybe_wrap_with_optional_by(body, optional_by, binary_value_access_bind, registered_callbacks_map, __MODULE__)
                )
              end

            end



        end


      :binary = binary_type ->

        case binary_type do

          :binary when not is_nil(length_by) ->

            ok_clause = Result.return_ok_tuple([field], __MODULE__)

            wrong_data_binary_bind = { :binary_for_wrong_data, [], __MODULE__ }

            validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, wrong_data_binary_bind, __MODULE__)

            body =

              quote do

                unquote(unmanaged_value_access) = unquote(binary_value_access_bind)

                unquote(
                  Validation.validate_and_return(validate_patterns_and_prelude, ok_clause, __MODULE__)
                )

              end

            quote do

              defp unquote(function_name)(
                     unquote(binary_value_access_bind),
                     unquote_splicing(dependencies_bindings),
                     options
                   ) when is_binary(unquote(binary_value_access_bind)) do


                unquote(
                  DeconstructionOfOnOptionDependencies.option_dependencies_deconstruction(dependencies, __MODULE__)
                )

                unquote(wrong_data_binary_bind) = unquote(binary_value_access_bind)

                unquote(
                  WrapWithLengthBy.wrap_with_length_by(body, length_by, binary_value_access_bind, registered_callbacks_map, __MODULE__)
                  |> WrapWithOptionalBy.maybe_wrap_with_optional_by(optional_by, binary_value_access_bind, registered_callbacks_map, __MODULE__)
                )
              end

            end

          :binary ->

            ok_clause =
              quote do
                { :ok, unquote(unmanaged_value_access), "", options }
              end

            wrong_data_binary_bind = { :binary_for_wrong_data, [], __MODULE__ }

            validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, wrong_data_binary_bind, __MODULE__)

            body =

              quote do

                unquote(unmanaged_value_access) = unquote(binary_value_access_bind)

                unquote(
                  Validation.validate_and_return(validate_patterns_and_prelude, ok_clause, __MODULE__)
                )

              end

            quote do

              defp unquote(function_name)(
                     unquote(binary_value_access_bind),
                     unquote_splicing(dependencies_bindings),
                     options
                   ) when is_binary(unquote(binary_value_access_bind)) do

                unquote(
                  DeconstructionOfOnOptionDependencies.option_dependencies_deconstruction(dependencies, __MODULE__)
                )

                unquote(wrong_data_binary_bind) = unquote(binary_value_access_bind)

                unquote(
                  WrapWithOptionalBy.maybe_wrap_with_optional_by(body, optional_by, binary_value_access_bind, registered_callbacks_map, __MODULE__)
                )
              end

            end

        end

    end

  end


end