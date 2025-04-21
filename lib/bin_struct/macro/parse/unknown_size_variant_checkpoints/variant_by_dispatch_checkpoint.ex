defmodule BinStruct.Macro.Parse.UnknownSizeVariantCheckpoints.VariantByDispatchCheckpoint do

  @moduledoc false

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Parse.Result
  alias BinStruct.Macro.Termination
  alias BinStruct.Macro.Parse.Validation
  alias BinStruct.Macro.Dependencies.DeconstructionOfOnOptionDependencies
  alias BinStruct.Macro.Parse.WrapWithOptionalBy
  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies

  def variant_by_dispatch_checkpoint(
        variants,
        field,
        function_name,
        dependencies,
        registered_callbacks_map,
        _env
      ) do

    dependencies_bindings = BindingsToOnFieldDependencies.bindings(dependencies, __MODULE__)

    %Field{ name: name, opts: opts } = field

    optional_by = opts[:optional_by]

    binary_value_access_bind = Bind.bind_binary_value(name, __MODULE__)
    unmanaged_value_access = Bind.bind_unmanaged_value(name, __MODULE__)

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

end
