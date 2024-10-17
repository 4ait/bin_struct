defmodule BinStruct.Macro.Parse.CheckpointOptionalByOfKnownSize do

  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Parse.WrapWithOptionalBy
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Parse.CheckpointKnownSize
  alias BinStruct.Macro.Parse.DeconstructOptionsForField
  alias BinStruct.Macro.Parse.ExternalFieldDependencies

  alias BinStruct.Macro.Structs.Field

  def checkpoint_optional_by_of_known_size([field] = _checkpoint, function_name, interface_implementations, registered_callbacks_map, env) do

    %Field{ name: name, opts: opts } = field

    optional_by = opts[:optional_by]

    field_name_access = { Bind.bind_value_name(name), [], __MODULE__ }

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

    parse_checkpoint_known_size_function_name = :"#{function_name}_inner"

    call_main_inner_function =
      quote do

        unquote(parse_checkpoint_known_size_function_name)(
          unquote(field_name_access),
          unquote_splicing(value_arguments_binds),
          options
        )

      end

    parse_checkpoint_known_size_function =
      CheckpointKnownSize.checkpoint_known_size(
        [field],
        parse_checkpoint_known_size_function_name,
        interface_implementations,
        registered_callbacks_map,
        env
      )


    check_is_opt_enabled_clause =

      quote do

        defp unquote(function_name)(
               unquote(field_name_access) = _bin,
               unquote_splicing(value_arguments_binds),
               options
             ) when is_binary(unquote(field_name_access)) do

          unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

          unquote(
            WrapWithOptionalBy.wrap_with_optional_by(
              call_main_inner_function,
              optional_by,
              field_name_access,
              registered_callbacks_map,
              __MODULE__
            )
          )

        end

      end

    main_clause =
      quote do

        defp unquote(function_name)(
               unquote(field_name_access) = _bin,
               unquote_splicing(value_arguments_binds),
               options
             ) when is_binary(unquote(field_name_access)) do

          unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))
          unquote(call_main_inner_function)

        end

      end

    [
      parse_checkpoint_known_size_function, check_is_opt_enabled_clause, main_clause
    ]

  end


end