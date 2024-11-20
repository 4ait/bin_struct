defmodule BinStruct.Macro.NewFunctionBuilderCalls do

  @moduledoc false

  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Dependencies.CallbacksDependencies
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField

  alias BinStruct.TypeConversion.TypeConversionBinary
  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionUnspecified

  alias BinStruct.Macro.RegisteredCallbackFunctionCall

  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.DependenciesTopology

  alias BinStruct.Macro.TypeConverterToUnmanaged
  alias BinStruct.Macro.TypeConverterToBinary

  alias BinStruct.Macro.OptionalNilCheckExpression
  alias BinStruct.Macro.IsOptionalField

  def builder_calls(fields, registered_callbacks_map, context) do

    fields_with_builder_ordered = fields_ordered_by_builder_calling_order(fields, registered_callbacks_map)

    Enum.reduce(
      fields_with_builder_ordered,
      { _builder_calls = [], _resolved_dependencies = [] },
      fn field, { builder_calls_acc, resolved_dependencies_acc } ->

        { name, opts } =
          case field do
            %Field{ name: name, opts: opts} -> { name, opts }
            %VirtualField{ name: name, opts: opts} ->  { name, opts }
          end

        builder_callback = Keyword.fetch!(opts, :builder)

        managed_value_access = Bind.bind_managed_value(name, context)

        registered_callback =
          RegisteredCallbacksMap.get_registered_callback_by_callback(
            registered_callbacks_map,
            builder_callback
          )

        builder_depends_on = CallbacksDependencies.dependencies([registered_callback])

        resolved_dependencies_with_info =
          Enum.map(
            builder_depends_on,
            fn dependency ->

              case dependency do

                %DependencyOnField{} = on_field_dependency ->

                  %DependencyOnField{
                    field: depend_on_field,
                    type_conversion: depend_on_type_conversion
                  } = on_field_dependency

                  depend_on_field_name =
                    case depend_on_field do
                      %Field{ name: name } -> name
                      %VirtualField{ name: name } ->  name
                    end

                  depend_on_field_type =
                    case depend_on_field do
                      %Field{ type: type } -> type
                      %VirtualField{ type: type } ->  type
                    end

                  is_optional =
                    case depend_on_field do
                      %Field{} = field -> IsOptionalField.is_optional_field(field)
                      %VirtualField{} ->  true
                    end

                  maybe_already_resolved =
                    Enum.find(
                      resolved_dependencies_acc,
                      fn { resolved_dependency_on_field_name, resolved_dependency_on_type_conversion } ->

                        resolved_dependency_on_field_name == depend_on_field_name &&
                          resolved_dependency_on_type_conversion == depend_on_type_conversion

                      end
                    )

                  case maybe_already_resolved do

                    nil ->
                      create_type_conversion_resolvers_with_resolved_info(
                        depend_on_field_name,
                        depend_on_field_type,
                        depend_on_type_conversion,
                        is_optional,
                        context
                      )

                    _already_resolved -> nil

                  end

                %DependencyOnOption{} -> nil

              end

            end
          )
          |> Enum.reject(&is_nil/1)
          |> List.flatten()


        { resolvers_code, resolvers_info } =

          Enum.reduce(
            resolved_dependencies_with_info,
            { [], [] },
            fn { resolver_code, resolvers_info }, { total_resolvers_code, total_resolvers_info } ->

              {  total_resolvers_code ++ [resolver_code], total_resolvers_info ++ resolvers_info}

            end
          )


        registered_callback_function_call =
          RegisteredCallbackFunctionCall.registered_callback_function_call(registered_callback, context)

        builder_call =
          quote do
            unquote_splicing(resolvers_code)
            unquote(managed_value_access) = unquote(registered_callback_function_call)
          end

        { builder_calls_acc ++ [ builder_call ], resolved_dependencies_acc ++ resolvers_info }

      end
    ) |> then(fn { builder_calls, _resolve_info } -> builder_calls end)

  end


  defp fields_ordered_by_builder_calling_order(fields, registered_callbacks_map) do

    fields_with_builder =
      Enum.filter(
        fields,
        fn field ->

          opts =
            case field do
              %Field{ opts: opts} -> opts
              %VirtualField{ opts: opts} -> opts
            end

          case opts[:builder] do
            builder_callback when not is_nil(builder_callback) -> true
            nil -> false

          end

        end
      )

    field_name_with_children_field_names =
      Enum.map(
        fields_with_builder,
        fn field ->

          { name, opts } =
            case field do
              %Field{ name: name, opts: opts} -> { name, opts }
              %VirtualField{ name: name, opts: opts} ->  { name, opts }
            end

          builder_callback = Keyword.fetch!(opts, :builder)

          registered_callback =
            RegisteredCallbacksMap.get_registered_callback_by_callback(
              registered_callbacks_map,
              builder_callback
            )

          %RegisteredCallback {
            arguments: arguments
          } = registered_callback

          builder_fields_dependencies =
            Enum.map(
              arguments,
              fn argument ->

                case argument do
                  %RegisteredCallbackFieldArgument{} = field_argument ->

                    %RegisteredCallbackFieldArgument{
                      field: field,
                    } = field_argument

                    case field do
                      %Field{ name: name } -> name
                      %VirtualField{ name: name } ->  name
                    end

                  %RegisteredCallbackOptionArgument{} -> nil
                end

              end
            )
            |> Enum.reject(&is_nil/1)

          { name, builder_fields_dependencies }

        end
      )

    topology = DependenciesTopology.find_dependencies_topology(field_name_with_children_field_names)

    case topology do
      { :ok, topology } ->

        Enum.sort_by(
          fields_with_builder,
          fn field ->

            field_name =
              case field do
                %Field{ name: field_name } -> field_name
                %VirtualField{ name: field_name } -> field_name
              end

            Enum.find_index(
              topology,
              fn field_name_in_topology -> field_name_in_topology == field_name end
            )

          end
        )
      { :error, :topology_not_exists } ->
        raise "circular dependencies in builder #{inspect(field_name_with_children_field_names)}"
    end

  end

  defp create_type_conversion_resolvers_with_resolved_info(
         depend_on_field_name,
         depend_on_field_type,
         depend_on_type_conversion,
         is_optional,
         context
       ) do


    depend_on_field_managed_value_access = Bind.bind_managed_value(depend_on_field_name, context)
    depend_on_field_unmanaged_value_access = Bind.bind_unmanaged_value(depend_on_field_name, context)
    depend_on_field_binary_value_access = Bind.bind_binary_value(depend_on_field_name, context)

    case depend_on_type_conversion do

      TypeConversionBinary ->

        unmanaged_value =
          TypeConverterToUnmanaged.convert_managed_value_to_unmanaged(
            depend_on_field_type,
            depend_on_field_managed_value_access
          )
          |> OptionalNilCheckExpression.maybe_wrap_optional(depend_on_field_managed_value_access, is_optional)

        binary_value =
          TypeConverterToBinary.convert_unmanaged_value_to_binary(
            depend_on_field_type,
            depend_on_field_unmanaged_value_access
          ) |> OptionalNilCheckExpression.maybe_wrap_optional(depend_on_field_unmanaged_value_access, is_optional)

        resolver =

          quote do
            unquote(depend_on_field_unmanaged_value_access) = unquote(unmanaged_value)
            unquote(depend_on_field_binary_value_access) = unquote(binary_value)
          end

        resolved = [
          { depend_on_field_name, TypeConversionUnmanaged },
          { depend_on_field_name, TypeConversionBinary }
        ]

        { resolver, resolved }

      TypeConversionUnmanaged ->

        unmanaged_value =
          TypeConverterToUnmanaged.convert_managed_value_to_unmanaged(
            depend_on_field_type,
            depend_on_field_managed_value_access
          ) |> OptionalNilCheckExpression.maybe_wrap_optional(depend_on_field_managed_value_access, is_optional)

        resolver =

          quote do
            unquote(depend_on_field_unmanaged_value_access) = unquote(unmanaged_value)
          end

        resolved = [
          { depend_on_field_name, TypeConversionUnmanaged }
        ]


        { resolver, resolved }

      TypeConversionManaged -> nil
      TypeConversionUnspecified -> nil
    end

  end


end