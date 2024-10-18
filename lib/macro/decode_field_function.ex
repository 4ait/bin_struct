defmodule BinStruct.Macro.DecodeFieldFunction do


  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.DecodeFunction
  alias BinStruct.Macro.Parse.CallbackDependenciesOnField
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.NonVirtualFields

  def decode_field_functions(fields, registered_callbacks_map, env) do

    non_virtual_fields = NonVirtualFields.skip_virtual_fields(fields)

    virtual_fields = fields -- non_virtual_fields

    virtual_fields_with_defined_read_by_callback =
      Enum.filter(
        virtual_fields,
        fn %VirtualField{} = virtual_field ->

          %VirtualField{ opts: opts } = virtual_field

          case opts[:read_by] do
            read_by when not is_nil(read_by) -> true
            nil -> false
          end

        end
      )

    Enum.map(
      non_virtual_fields ++ virtual_fields_with_defined_read_by_callback,
      fn field ->
        BinStruct.Macro.DecodeFieldFunction.decode_field_function(field, registered_callbacks_map, env)
      end
    )

  end

  def decode_field_function(%Field{} = field, _registered_callbacks_map, _env) do

    %Field{ name: name, type: type, opts: opts } = field

    value_access = { Bind.bind_value_name(name), [], __MODULE__ }
    deep_access = { :deep, [], __MODULE__ }

    is_optional = BinStruct.Macro.IsOptionalField.is_optional_field(field)

    decode_type_expr = DecodeFunction.decode_type(type, opts, value_access, deep_access)

    decode_type_expr_with_maybe_optional_check =
      if is_optional do
        DecodeFunction.decode_expr_wrap_optional(decode_type_expr, value_access)
      else
        decode_type_expr
      end

    quote do

      def decode_field(%__MODULE__{ unquote(name) => unquote(value_access) }, unquote(name), opts) do

        unquote(deep_access) =
          case opts[:deep] do
            nil -> false
            value when is_boolean(value) -> value
          end

        unquote(decode_type_expr_with_maybe_optional_check)

      end

    end

  end

  def decode_field_function(%VirtualField{} = virtual_field, registered_callbacks_map, _env) do

    %VirtualField{ name: name, type: type, opts: opts } = virtual_field

    read_by = opts[:read_by]

    read_by_registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, read_by)

    read_by_registered_callback_call = RegisteredCallbackFunctionCall.registered_callback_function_call(read_by_registered_callback, __MODULE__)

    value_access = { Bind.bind_value_name(name), [], __MODULE__ }
    deep_access = { :deep, [], __MODULE__ }

    field_dependencies = CallbackDependenciesOnField.field_dependencies_of_callbacks([read_by], registered_callbacks_map)

    struct_deconstruction_fields =
      Enum.map(
        field_dependencies,
        fn %RegisteredCallbackFieldArgument{} = field_argument ->

          %RegisteredCallbackFieldArgument{
            field: %Field{} = field
          } = field_argument

          %Field{name: name} = field

          { name, { Bind.bind_value_name(name), [], __MODULE__ } }
        end
      ) |> Keyword.new()

    decode_type_expr = DecodeFunction.decode_type(type, opts, value_access, deep_access)

    is_optional =
      case opts[:optional] do
        optional when is_boolean(optional) -> optional
        _ -> false
      end

    decode_type_expr_with_maybe_empty_binary_check =
      if is_optional do
        DecodeFunction.decode_expr_wrap_empty_binary(decode_type_expr, value_access)
      else
        decode_type_expr
      end

    quote do

      def decode_field(%__MODULE__{ unquote_splicing(struct_deconstruction_fields) }, unquote(name), opts) do

        unquote(deep_access) =
          case opts[:deep] do
            nil -> false
            value when is_boolean(value) -> value
          end

        unquote(value_access) = unquote(read_by_registered_callback_call)

        unquote(decode_type_expr_with_maybe_empty_binary_check)

      end

    end

  end

end