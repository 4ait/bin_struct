defmodule BinStruct.Macro.NewFunction do

  @moduledoc false

  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.IsOptionalField
  alias BinStruct.Macro.NonVirtualFields
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.TypeConverterToUnmanaged

  alias BinStruct.Macro.NewFunctionBuilderCalls


  defp default_value_initialization(field, env) do

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

                { default_escaped, _binding } = Code.eval_quoted(default, [], env)

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


  def new_function(fields, %RegisteredCallbacksMap{} = registered_callbacks_map, env) do

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
        fn field ->
          default_value_initialization(field, env)
        end
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

    builder_calls =
      NewFunctionBuilderCalls.builder_calls(
        fields,
        registered_callbacks_map,
        __MODULE__
      )

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

end