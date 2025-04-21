defmodule BinStruct.Macro.Parse.Validation do

  @moduledoc false

  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Dependencies.CallbacksDependencies
  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionUnspecified
  alias BinStruct.TypeConversion.TypeConversionBinary

  def validate_and_return(validate_fields_with_patterns_and_prelude, return_ok_clause, _context) do

      case validate_fields_with_patterns_and_prelude do

        {  [], _prelude } -> return_ok_clause

        { patterns, nil } ->

          quote do

            with unquote_splicing(patterns) do
              unquote(return_ok_clause)
            end

          end

        { patterns, prelude } ->

          quote do

            unquote(prelude)

            with unquote_splicing(patterns) do
              unquote(return_ok_clause)
            end

          end

      end

  end

  defp is_valid_bind(name) do
    { String.to_atom("is_valid_#{name}"), [], __MODULE__ }
  end

  def validate_fields_with_patterns_and_prelude(
        fields,
        %RegisteredCallbacksMap{} = registered_callbacks_map,
        wrong_data_binary_bind,
        context
      ) do

    validate_by_patterns_and_preludes =
        Enum.map(
          fields,
          fn %Field{} = field ->

            %Field{ name: name, type: type, opts: opts } = field

            is_valid_access_field = is_valid_bind(name)

            validate_by = opts[:validate_by]

            case type do

              _type when not is_nil(validate_by) ->

                validate_by = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, validate_by)

                %{
                  has_dependency_on_managed: has_dependency_on_managed,
                  has_dependency_on_unspecified: has_dependency_on_unspecified,
                  has_dependency_on_unmanaged: _has_dependency_on_unmanaged,
                  has_dependency_on_binary: has_dependency_on_binary
                } = validate_by_dependency_on_self_info(name, validate_by)

                has_dependency_on_managed = has_dependency_on_managed || has_dependency_on_unspecified

                managed_value_bind = Bind.bind_managed_value(name, context)
                unmanaged_value_bind = Bind.bind_unmanaged_value(name, context)
                binary_value_bind = Bind.bind_binary_value(name, context)

                #unmanaged value should be available always

                #validate by callback should be provided with required args
                #all external fields will be provided by checkpoint itself
                #in case callback needs self we need supply it with appropriate type conversion

                validate_by_function_call =
                  RegisteredCallbackFunctionCall.registered_callback_function_call(
                    validate_by,
                    context
                  )

                  maybe_bind_to_managed_self =

                    if has_dependency_on_managed do

                      quote do

                        unquote(managed_value_bind) =
                          unquote(
                            BinStruct.Macro.TypeConverterToManaged.convert_unmanaged_value_to_managed(type, unmanaged_value_bind)
                          )

                      end

                    end

                maybe_bind_to_binary_self =

                  if has_dependency_on_binary do

                    quote do

                      unquote(binary_value_bind) =
                        unquote(
                          BinStruct.Macro.TypeConverterToBinary.convert_unmanaged_value_to_binary(type, unmanaged_value_bind)
                        )

                    end

                  end

                type_conversion_binds =
                  [ maybe_bind_to_managed_self, maybe_bind_to_binary_self ]
                  |> Enum.reject(&is_nil/1)

                prelude =
                  quote do

                    unquote_splicing(type_conversion_binds)

                    unquote(is_valid_access_field) = unquote(validate_by_function_call)

                  end

                pattern =
                  quote do
                    :ok <- (if unquote(is_valid_access_field), do: :ok, else: { :wrong_data, unquote(wrong_data_binary_bind) })
                  end

                { pattern, prelude }

              _ -> nil

            end

          end
        ) |> Enum.reject(&is_nil/1)


      patterns =
        Enum.map(
          validate_by_patterns_and_preludes,
          fn { pattern, _prelude } ->
            pattern
          end
        )

      preludes =
        Enum.map(
          validate_by_patterns_and_preludes,
          fn { _pattern, prelude } ->
            prelude
          end
        ) |> Enum.reject(&is_nil/1)

      prelude =
        case preludes do

         [] -> nil

         preludes ->

           quote do
             unquote_splicing(preludes)
           end

        end


      { patterns, prelude }

  end

  defp validate_by_dependency_on_self_info(current_field_name, validate_by_registered_callback) do

    validate_by_dependencies = CallbacksDependencies.dependencies([validate_by_registered_callback])

    dependency_on_self_for_type_conversions =
      Enum.reduce(
        validate_by_dependencies,
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
        dependency_on_self_for_type_conversions,
        fn type_conversion -> type_conversion == TypeConversionManaged end
      )

    has_dependency_on_unspecified =
      Enum.any?(
        dependency_on_self_for_type_conversions,
        fn type_conversion -> type_conversion == TypeConversionUnspecified end
      )


    has_dependency_on_unmanaged =
      Enum.any?(
        dependency_on_self_for_type_conversions,
        fn type_conversion -> type_conversion == TypeConversionUnmanaged end
      )

    has_dependency_on_binary =
      Enum.any?(
        dependency_on_self_for_type_conversions,
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