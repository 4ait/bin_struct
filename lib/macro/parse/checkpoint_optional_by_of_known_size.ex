defmodule BinStruct.Macro.Parse.CheckpointOptionalByOfKnownSize do

  alias BinStruct.Macro.Parse.WrapWithOptionalBy
  alias BinStruct.Macro.Parse.CheckpointKnownSize
  alias BinStruct.Macro.Dependencies.DeconstructionOfOnOptionDependencies

  alias BinStruct.Macro.Structs.Field
  
  alias BinStruct.Macro.Dependencies.ParseDependencies
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies

  def checkpoint_optional_by_of_known_size([field] = _checkpoint, function_name, registered_callbacks_map, env) do

    %Field{ opts: opts } = field

    optional_by = opts[:optional_by]

    dependencies = ParseDependencies.parse_dependencies([field], registered_callbacks_map)
    dependencies_bindings = BindingsToOnFieldDependencies.bindings(dependencies, __MODULE__)

    parse_checkpoint_known_size_function_name = :"#{function_name}_inner"

    parse_checkpoint_known_size_function =
      CheckpointKnownSize.checkpoint_known_size(
        [field],
        parse_checkpoint_known_size_function_name,
        registered_callbacks_map,
        env
      )

    initial_binary_access = { :bin, [], __MODULE__ }

    call_main_inner_function =
      quote do

        unquote(parse_checkpoint_known_size_function_name)(
          unquote(initial_binary_access),
          unquote_splicing(dependencies_bindings),
          options
        )

      end


    check_is_opt_enabled_clause =

      quote do

        defp unquote(function_name)(
               unquote(initial_binary_access),
               unquote_splicing(dependencies_bindings),
               options
             ) when is_binary(unquote(initial_binary_access)) do

          unquote(
            DeconstructionOfOnOptionDependencies.option_dependencies_deconstruction(dependencies, __MODULE__)
          )

          unquote(
            WrapWithOptionalBy.wrap_with_optional_by(
              call_main_inner_function,
              optional_by,
              initial_binary_access,
              registered_callbacks_map,
              __MODULE__
            )
          )

        end

      end

    main_clause =
      quote do

        defp unquote(function_name)(
               unquote(initial_binary_access),
               unquote_splicing(dependencies_bindings),
               options
             ) when is_binary(unquote(initial_binary_access)) do

          unquote(
            DeconstructionOfOnOptionDependencies.option_dependencies_deconstruction(dependencies, __MODULE__)
          )

          unquote(call_main_inner_function)

        end

      end

    [
      parse_checkpoint_known_size_function, check_is_opt_enabled_clause, main_clause
    ]

  end


end