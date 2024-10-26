defmodule BinStruct.Macro.NewFunction do

  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.DependenciesTopology
  alias BinStruct.Macro.IsOptionalField
  alias BinStruct.Macro.NonVirtualFields
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.Dependencies.CallbacksDependencies
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.TypeConversion.TypeConversionBinary
  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionUnspecified
  alias BinStruct.Macro.TypeConverterToUnmanaged
  alias BinStruct.Macro.TypeConverterToBinary


  defp default_value_initialization(field) do

    %{ name: name, type: type, opts: opts } =
      case field do
        %Field{ name: name, type: type, opts: opts } -> %{ name: name, type: type, opts: opts }
        %VirtualField{ name: name, type: type, opts: opts } -> %{ name: name, type: type, opts: opts }
      end

    is_optional =
      case opts[:optional] do
         true -> true
         _  -> false
      end

    is_optional_by =
      case opts[:optional_by] do
        optional_by when not is_nil(optional_by) -> true
        _  -> false
      end

    is_any_kind_optional = is_optional || is_optional_by

    has_default_option =
      case opts[:default] do
        default when not is_nil(default) -> true
        _ -> false
      end

    is_static_value =
      case type do
        { :static_value, _static_value_info } -> true
        _ -> false
      end


    has_default_value = has_default_option || is_static_value

    managed_value_access = Bind.bind_managed_value(name, __MODULE__)

    if has_default_value do

         default_kind =
           cond do
             has_default_option ->

                default = opts[:default]
                default_escaped = Macro.escape(default)

               { :default, default_escaped }
             is_static_value ->
               { :static_value, static_value_info } = type
               { :static_value, static_value_info }
           end

         if is_any_kind_optional do

           case default_kind do

             { :default, default } ->

               quote do

                 unquote(managed_value_access) =
                   case unquote(managed_value_access) do
                     :present -> unquote(default)
                     user_value when not is_nil(user_value) -> user_value
                     nil -> nil
                   end

               end

             { :static_value, %{ value: static_value } } ->

               quote do

                 unquote(managed_value_access) =
                   case unquote(managed_value_access) do
                     :present -> unquote(static_value)
                     user_value when not is_nil(user_value) -> user_value
                     nil -> nil
                   end

               end

           end

         else

           case default_kind do

             { :default, default } ->

               quote do

                 unquote(managed_value_access) =
                   case unquote(managed_value_access) do
                     user_value when not is_nil(user_value) -> user_value
                     nil -> unquote(default)
                   end

               end

             { :static_value, %{ value: static_value } } ->

               quote do

                 unquote(managed_value_access) =
                   case unquote(managed_value_access) do
                     user_value when not is_nil(user_value) -> user_value
                     nil -> unquote(static_value)
                   end

               end

             end

         end

    end

  end

  defp encode_non_virtual_field(%Field{} = field) do

    %Field{ name: name, type: type } = field

    managed_value_access = Bind.bind_managed_value(name, __MODULE__)

    encode_expr = TypeConverterToUnmanaged.convert_managed_value_to_unmanaged(type, managed_value_access)

    case encode_expr do
      ^managed_value_access -> nil

      encode_expr ->

        is_optional = IsOptionalField.is_optional_field(field)

        case is_optional do

          true ->

            quote do
              unquote(managed_value_access) =
                case unquote(managed_value_access) do
                  nil -> nil
                  unquote(managed_value_access) -> unquote(encode_expr)
                end
            end

          false ->

            quote do
              unquote(managed_value_access) = unquote(encode_expr)
            end

        end

    end

  end

  defp create_type_conversion_resolvers_with_resolved_info(
         depend_on_field_name,
         depend_on_field_type,
         depend_on_type_conversion
       ) do


    depend_on_field_managed_value_access = Bind.bind_managed_value(depend_on_field_name, __MODULE__)
    depend_on_field_unmanaged_value_access = Bind.bind_unmanaged_value(depend_on_field_name, __MODULE__)
    depend_on_field_binary_value_access = Bind.bind_binary_value(depend_on_field_name, __MODULE__)

    case depend_on_type_conversion do
      TypeConversionBinary ->

        unmanaged_value =
          TypeConverterToUnmanaged.convert_managed_value_to_unmanaged(
            depend_on_field_type,
            depend_on_field_managed_value_access
          )

        binary_value =
          TypeConverterToBinary.convert_unmanaged_value_to_binary(
            depend_on_field_type,
            depend_on_field_unmanaged_value_access
          )

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
          )

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


  def new_function(fields, %RegisteredCallbacksMap{} = registered_callbacks_map) do

    non_virtual_fields = NonVirtualFields.skip_virtual_fields(fields)

    default_values_nil_kv =
      Enum.map(
        fields,
        fn field ->

          field_name =
            case field do
              %Field{ name: field_name } -> field_name
              %VirtualField{ name: field_name } -> field_name
            end

          { field_name, nil }

        end
      )

    default_values_initialization =
      Enum.map(
        fields,
        &default_value_initialization/1
      )
      |> Enum.reject(&is_nil/1)

    args_deconstruction_fields =
      Enum.map(
        fields,
        fn field ->

          name =
            case field do
              %Field{ name: name } = _field -> name
              %VirtualField{ name: name } = _virtual_field -> name
            end

          { name, Bind.bind_managed_value(name, __MODULE__) }

        end
      )

    fields_with_builder_ordered = fields_ordered_by_builder_calling_order(fields, registered_callbacks_map)

    builder_calls =
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

          managed_value_access = Bind.bind_managed_value(name, __MODULE__)

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
                          depend_on_type_conversion
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


          registered_callback_function_call = RegisteredCallbackFunctionCall.registered_callback_function_call(registered_callback, __MODULE__)

          builder_call =
            quote do
              unquote_splicing(resolvers_code)
              unquote(managed_value_access) = unquote(registered_callback_function_call)
            end

          { builder_calls_acc ++ [ builder_call ], resolved_dependencies_acc ++ resolvers_info }

        end
      ) |> then(fn { builder_calls, _resolve_info } -> builder_calls end)

    encoder_calls =
      Enum.map(
        non_virtual_fields,
        fn %Field{} = field ->
          encode_non_virtual_field(field)
        end
      ) |> Enum.reject(&is_nil/1)


    returning_kv =
      Enum.map(
        non_virtual_fields,
        fn %Field{} = field ->

          %Field{ name: name } = field

          managed_value_access = Bind.bind_managed_value(name, __MODULE__)

          { name, managed_value_access }

        end
      )

    quote do

      def new(args \\ %{})

      def new(args) when is_list(args) do

        new(
          Enum.into(args, %{})
        )

      end

      def new(args) when is_map(args) do

        all_fields_initialized_as_nil = %{
          unquote_splicing(default_values_nil_kv)
        }

        %{
          unquote_splicing(args_deconstruction_fields)
        } = :maps.merge(all_fields_initialized_as_nil, args)

        unquote_splicing(
          default_values_initialization
        )

        unquote_splicing(builder_calls)

        unquote_splicing(encoder_calls)

        %__MODULE__{
          unquote_splicing(returning_kv)
        }

      end

    end

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

end