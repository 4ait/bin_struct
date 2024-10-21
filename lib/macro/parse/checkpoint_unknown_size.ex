defmodule BinStruct.Macro.Parse.CheckpointUnknownSize do

  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Parse.Validation
  alias BinStruct.Macro.Parse.Result
  alias BinStruct.Macro.Parse.WrapWithLengthBy
  alias BinStruct.Macro.Parse.WrapWithOptionalBy
  alias BinStruct.Macro.Termination
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Parse.ListOfRuntimeBounds
  alias BinStruct.Macro.IsPrimitiveType
  alias BinStruct.Macro.Parse.CheckpointVariableList
  alias BinStruct.Macro.Parse.DeconstructOptionsForField
  alias BinStruct.Macro.Parse.ExternalFieldDependencies

  alias BinStruct.Macro.Structs.Field

  def checkpoint_unknown_size([ field ] = _checkpoint, function_name, interface_implementations, registered_callbacks_map, env) do

    %Field{ name: name, type: type, opts: opts } = field

    length_by = opts[:length_by]
    optional_by = opts[:optional_by]

    binary_value_access_bind = Bind.bind_binary_value(name, __MODULE__)

    external_field_dependencies = ExternalFieldDependencies.external_field_dependencies([field], interface_implementations, registered_callbacks_map)

    value_arguments_binds =
      Enum.map(
        external_field_dependencies,
        fn argument ->

          case argument do
            %RegisteredCallbackFieldArgument{ field: %Field{ name: name } } ->
              { Bind.bind_value_name(name), [], __MODULE__ }

          end

        end
      )

    case type do

      { :list_of, list_of_info } ->

        case list_of_info do

          %{ type: :runtime_bounded } = list_of_info ->
            runtime_bounded_list_checkpoint(
              list_of_info,
              field,
              function_name,
              value_arguments_binds,
              interface_implementations,
              registered_callbacks_map,
              env
            )

          %{
            type: :variable,
            termination: :terminated,
            take: :until_length_by_parse
          } = list_of_info
            -> CheckpointVariableList.variable_terminated_until_length_by_parse_checkpoint(
                 list_of_info,
                 field,
                 function_name,
                 give_binds(value_arguments_binds, CheckpointVariableList),
                 interface_implementations,
                 registered_callbacks_map,
                 env
               )

          %{
            type: :variable,
            termination: :terminated,
            take: :until_count_by_parse
          } = list_of_info
            -> CheckpointVariableList.variable_terminated_until_count_by_parse_checkpoint(
                 list_of_info,
                 field,
                 function_name,
                 give_binds(value_arguments_binds, CheckpointVariableList),
                 interface_implementations,
                 registered_callbacks_map,
                 env
               )


          %{
            type: :variable,
            termination: :terminated,
            take: :take_while_by_callback_by_item_size
          } = list_of_info
          -> CheckpointVariableList.variable_terminated_take_while_by_callback_by_item_size_checkpoint(
               list_of_info,
               field,
               function_name,
               give_binds(value_arguments_binds, CheckpointVariableList),
               interface_implementations,
               registered_callbacks_map,
               env
             )

          %{
            type: :variable,
            termination: :terminated,
            take: :take_while_by_callback_by_parse
          } = list_of_info
          -> CheckpointVariableList.variable_terminated_take_while_by_callback_by_parse_checkpoint(
               list_of_info,
               field,
               function_name,
               give_binds(value_arguments_binds, CheckpointVariableList),
               interface_implementations,
               registered_callbacks_map,
               env
             )

          %{
            type: :variable,
            termination: :not_terminated,
            take: :until_end_by_item_size
          } = list_of_info
          -> CheckpointVariableList.variable_not_terminated_until_end_by_item_size_checkpoint(
               list_of_info,
               field,
               function_name,
               give_binds(value_arguments_binds, CheckpointVariableList),
               interface_implementations,
               registered_callbacks_map,
               env
             )

          %{
            type: :variable,
            termination: :not_terminated,
            take: :until_end_by_parse
          } = list_of_info
          -> CheckpointVariableList.variable_not_terminated_until_end_by_parse_checkpoint(
               list_of_info,
               field,
               function_name,
               give_binds(value_arguments_binds, CheckpointVariableList),
               interface_implementations,
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

            validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, __MODULE__)

            validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, ok_clause, __MODULE__)

            body =
              quote do

                not_enough_bytes_seen = false

                unquote(binary_value_access_bind) =
                  with unquote_splicing(with_patterns_variants_parsing) do

                    case not_enough_bytes_seen do
                      true -> :not_enough_bytes
                      false ->  { :wrong_data, unquote(binary_value_access_bind) }
                    end

                  end

                case unquote(binary_value_access_bind) do
                  {:ok, unquote(binary_value_access_bind), options } -> unquote(validate_and_return_clause)
                  { :wrong_data, _wrong_data } = wrong_data_clause -> wrong_data_clause
                  :not_enough_bytes -> :not_enough_bytes
                end

              end
              

            quote do

              defp unquote(function_name)(unquote(binary_value_access_bind) = _bin,
                     unquote_splicing(value_arguments_binds),
                     options
                   ) when is_binary(unquote(binary_value_access_bind)) do

                unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

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

            validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, __MODULE__)

            validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, ok_clause, __MODULE__)

            body =
              quote do

                not_enough_bytes_seen = false

                unquote(binary_value_access_bind) =
                  with unquote_splicing(with_patterns_variants_parsing) do

                    case not_enough_bytes_seen do
                      true -> :not_enough_bytes
                      false ->  { :wrong_data, unquote(binary_value_access_bind) }
                    end

                  end

                case unquote(binary_value_access_bind) do
                  { :ok, unquote(binary_value_access_bind), rest, options } -> unquote(validate_and_return_clause)
                  { :wrong_data, _wrong_data } = wrong_data_clause -> wrong_data_clause
                  :not_enough_bytes -> :not_enough_bytes
                end

              end

            quote do

              defp unquote(function_name)(
                     unquote(binary_value_access_bind) = _bin,
                     unquote_splicing(value_arguments_binds),
                     options
                   ) when is_binary(unquote(binary_value_access_bind)) do

                unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

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
                  { :ok, unquote(binary_value_access_bind), options } -> unquote(Result.return_ok_tuple([field], __MODULE__))
                  { :wrong_data, _wrong_data } = wrong_data -> wrong_data
                end

              end

            validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, __MODULE__)

            validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, ok_clause, __MODULE__)

            quote do

              defp unquote(function_name)(
                     unquote(binary_value_access_bind) = _bin,
                     unquote_splicing(value_arguments_binds),
                     options
                   ) when is_binary(unquote(binary_value_access_bind)) do

                unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

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
                  { :ok, unquote(binary_value_access_bind), options } ->
                    rest = ""
                    unquote(Result.return_ok_tuple([field], __MODULE__))
                  { :wrong_data, _wrong_data } = wrong_data -> wrong_data
                end

              end

            validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, __MODULE__)

            validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, ok_clause, __MODULE__)

            quote do

              defp unquote(function_name)(
                     unquote(binary_value_access_bind) = _bin,
                     unquote_splicing(value_arguments_binds),
                     options
                   ) when is_binary(unquote(binary_value_access_bind)) do

                unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

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

            validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, __MODULE__)

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

                  { :ok, unquote(binary_value_access_bind), rest, options } -> unquote(validate_and_return_clause)
                  { :wrong_data, _wrong_data } = wrong_data_clause -> wrong_data_clause
                  :not_enough_bytes -> :not_enough_bytes

                end

              end

            quote do

              defp unquote(function_name)(
                     unquote(binary_value_access_bind) = _bin,
                     unquote_splicing(value_arguments_binds),
                     options
                   ) when is_binary(unquote(binary_value_access_bind)) do

                unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

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

            validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, __MODULE__)

            body = Validation.validate_and_return(validate_patterns_and_prelude, ok_clause, __MODULE__)

            quote do

              defp unquote(function_name)(
                     unquote(binary_value_access_bind) = _bin,
                     unquote_splicing(value_arguments_binds),
                     options
                   ) when is_binary(unquote(binary_value_access_bind)) do

                unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

                unquote(
                  WrapWithLengthBy.wrap_with_length_by(body, length_by, binary_value_access_bind, registered_callbacks_map, __MODULE__)
                  |> WrapWithOptionalBy.maybe_wrap_with_optional_by(optional_by, binary_value_access_bind, registered_callbacks_map, __MODULE__)
                )
              end

            end

          :binary ->

            ok_clause =
              quote do
                { :ok, unquote(binary_value_access_bind), "", options }
              end

            validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, __MODULE__)

            body = Validation.validate_and_return(validate_patterns_and_prelude, ok_clause, __MODULE__)

            quote do

              defp unquote(function_name)(
                     unquote(binary_value_access_bind) = _bin,
                     unquote_splicing(value_arguments_binds),
                     options
                   ) when is_binary(unquote(binary_value_access_bind)) do

                unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

                unquote(
                  WrapWithOptionalBy.maybe_wrap_with_optional_by(body, optional_by, binary_value_access_bind, registered_callbacks_map, __MODULE__)
                )
              end

            end

        end

    end

  end


  defp runtime_bounded_list_checkpoint(
        %{ type: :runtime_bounded } = list_of_info,
         %Field{} = field,
         function_name,
         value_arguments_binds,
         interface_implementations,
         registered_callbacks_map,
         _env
       ) do

    %{
      bounds: bounds,
      item_type: item_type
    } = list_of_info

    %Field{name: name, opts: opts} = field

    binary_value_access_bind = { Bind.bind_value_name(name), [], __MODULE__ }
    rest_bind = { :rest, [], __MODULE__ }
    item_binary_bind = { :item_binary, [], __MODULE__ }

    optional_by = opts[:optional_by]

    runtime_bounds_expr = ListOfRuntimeBounds.get_runtime_bounds(bounds, registered_callbacks_map, __MODULE__)

    is_item_of_primitive_type = IsPrimitiveType.is_primitive_type(item_type)

    parse_expr =

      case item_type do

        _item_type when is_item_of_primitive_type -> item_binary_bind

        {:module, module_info} ->

          module_parse_expr =

            case module_info do

              %{ module_type: :bin_struct, module: module } ->

                quote do
                  unquote(module).parse_returning_options(unquote(item_binary_bind), options)
                end

              %{
                module_type: :bin_struct_custom_type,
                module: module,
                custom_type_args: custom_type_args
              } ->
                quote do
                  unquote(module).parse_returning_options(unquote(item_binary_bind), unquote(custom_type_args), options)
                end
            end

          quote do
            { :ok, struct, _options } = unquote(module_parse_expr)
            struct
          end

      end

    body =
      quote do

        %{
          length: length,
          count: _count,
          item_size: item_size,
        } = unquote(runtime_bounds_expr)

        if byte_size(unquote(binary_value_access_bind)) >= length do

          <<target_binary::size(length)-bytes, unquote(rest_bind)::binary>> = unquote(binary_value_access_bind)

          items =
            for << unquote(item_binary_bind)::binary-size(item_size) <- target_binary >> do
              unquote(parse_expr)
            end

          { :ok, items, unquote(rest_bind), options }

        else
          :not_enough_bytes
        end

      end

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, __MODULE__)

    validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, body, __MODULE__)

    quote do

      defp unquote(function_name)(
             unquote(binary_value_access_bind) = _bin,
             unquote_splicing(value_arguments_binds),
             options
        ) when is_binary(unquote(binary_value_access_bind)) do

        unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

        unquote(
          WrapWithOptionalBy.maybe_wrap_with_optional_by(validate_and_return_clause, optional_by, binary_value_access_bind, registered_callbacks_map, __MODULE__)
        )
      end

    end

  end


  defp give_binds(binds, context) do

    Enum.map(
      binds,
      fn { name, [], _context } ->  { name, [], context }  end
    )

  end


end