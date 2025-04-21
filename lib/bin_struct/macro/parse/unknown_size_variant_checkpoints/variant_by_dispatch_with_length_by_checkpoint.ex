defmodule BinStruct.Macro.Parse.UnknownSizeVariantCheckpoints.VariantByDispatchWithLengthByCheckpoint do

  @moduledoc false

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Parse.Result
  alias BinStruct.Macro.Parse.Validation
  alias BinStruct.Macro.Dependencies.DeconstructionOfOnOptionDependencies
  alias BinStruct.Macro.Parse.WrapWithOptionalBy
  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies
  alias BinStruct.Macro.Parse.WrapWithLengthBy

  def variant_by_dispatch_with_length_by_checkpoint(
        variants,
        length_by,
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

            { :no_match, _reason } <-

              (

                case unquote(parse_exact_expr) do
                  { :ok, _variant, _options } = ok_result ->  ok_result
                  { :wrong_data, _wrong_data } = wrong_data -> { :no_match, wrong_data }
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
            { :wrong_data, unquote(binary_value_access_bind) }
          end

        case result do
          {:ok, unquote(unmanaged_value_access), options } -> unquote(validate_and_return_clause)
          { :wrong_data, _wrong_data } = wrong_data_clause -> wrong_data_clause
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

  end


end
