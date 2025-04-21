defmodule BinStruct.Macro.Parse.UnknownSizeVariantCheckpoints.VariantBySelectVariantCallbackWithLengthByCheckpoint do

  @moduledoc false

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies
  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Parse.Result
  alias BinStruct.Macro.Parse.Validation
  alias BinStruct.Macro.Parse.WrapWithLengthBy
  alias BinStruct.Macro.Parse.WrapWithOptionalBy
  alias BinStruct.Macro.Dependencies.DeconstructionOfOnOptionDependencies

  def variant_by_select_variant_callback_with_length_by_checkpoint(
        variants,
        select_variant_by,
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

    select_variant_by_registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, select_variant_by)

    parse_expr =

      quote do

        variant_by_call = unquote(
          RegisteredCallbackFunctionCall.registered_callback_function_call(
            select_variant_by_registered_callback,
            __MODULE__
          )
        )

        case variant_by_call do

          unquote(

            Enum.map(
              variants,
              fn variant ->

                {:module, module_info } = variant

                case module_info do

                  %{ module_type: :bin_struct, module: module } ->

                    bin_struct_parse_expr =
                      quote do
                        unquote(module).parse_exact_returning_options(unquote(binary_value_access_bind), options)
                      end

                    BinStruct.Macro.Common.case_pattern(module, bin_struct_parse_expr)

                  %{
                    module_type: :bin_struct_custom_type,
                    module: module,
                    custom_type_args: custom_type_args
                  } ->

                    bin_struct_custom_type_parse_expr =
                      quote do
                        unquote(module).parse_exact_returning_options(unquote(binary_value_access_bind), unquote(custom_type_args), options)
                      end

                    BinStruct.Macro.Common.case_pattern(module, bin_struct_custom_type_parse_expr)

                end

              end
            )
          )

        end

      end

    ok_clause = Result.return_ok_tuple([field], __MODULE__)

    wrong_data_binary_bind = { :binary_for_wrong_data, [], __MODULE__ }

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, wrong_data_binary_bind, __MODULE__)
    validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, ok_clause, __MODULE__)

    body = quote do

      result = unquote(parse_expr)

      case result do
        { :ok, unquote(unmanaged_value_access), options } -> unquote(validate_and_return_clause)
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
