defmodule BinStruct.Macro.Decode.DecodeFunctionOld do

  @moduledoc false

  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.NonVirtualFields
  alias BinStruct.Macro.IsOptionalField
  alias BinStruct.Macro.TypeConverterToManaged
  alias BinStruct.Macro.Decode.DecodeFunctionReadByCalls

  #assuming we have managed type, such type to work people expect most comfortable to work this
  #and unmanaged type we expect it to be close to stream of binary for easy parse/dump binaries

  #we will try to abstract away from decode/encode naming in any internals

  def decode_expr_wrap_empty_binary(read_expr, value_access) do

    quote do

      case unquote(value_access) do
        <<>> -> nil
        _ -> unquote(read_expr)
      end

    end

  end

  def decode_expr_wrap_optional(read_expr, value_access) do

    quote do

      case unquote(value_access) do
        nil -> nil
        _ -> unquote(read_expr)
      end

    end

  end


  def decode_type(type, _opts, value_access) do

      case type do

        { :variant_of, _variants } -> value_access


        { :module, module_info } ->

          case module_info do

            %{
              module_type: :bin_struct,
              module: _module
            } -> value_access

            %{
              module_type: :bin_struct_custom_type,
              module: module,
              custom_type_args: custom_type_args
            } ->

              quote do
                unquote(module).from_unmanaged_to_managed(unquote(value_access), unquote(custom_type_args))
              end

          end


        { :list_of, %{ item_type: { :module, module_info } } } ->

          case module_info do

            %{
              module_type: :bin_struct,
              module: _module
            } -> value_access

            %{
              module_type: :bin_struct_custom_type,
              module: _module,
              custom_type_args: _custom_type_args
            } -> value_access

          end

        { :list_of, %{ item_type: item_type } } ->

          quote do

            Enum.map(
              unquote(value_access),
              fn unquote(value_access) ->
                unquote(TypeConverterToManaged.convert_unmanaged_value_to_managed(item_type, value_access))
              end
            )

          end

        type -> TypeConverterToManaged.convert_unmanaged_value_to_managed(type, value_access)

      end



  end

  defp decode_field(%Field{} = field, _env) do

    %Field{ name: name, type: type, opts: opts} = field

    unmanaged_value_access = Bind.bind_unmanaged_value(name, __MODULE__)

    decode_type_expr = decode_type(type, opts, unmanaged_value_access)

    is_optional = IsOptionalField.is_optional_field(field)

    if is_optional do
      decode_expr_wrap_optional(decode_type_expr, unmanaged_value_access)
    else
      decode_type_expr
    end

  end

  def decode_function(fields, registered_callbacks_map, env) do

    non_virtual_fields = NonVirtualFields.skip_virtual_fields(fields)

    struct_fields =
      Enum.map(
        non_virtual_fields,
        fn %Field{} = field ->

          %Field{ name: name } = field

          { name, Bind.bind_unmanaged_value(name, __MODULE__) }

        end
      )

    managed_values_bindings =
      Enum.map(
        non_virtual_fields,
        fn field ->

          %Field{ name: name } = field

          managed_value_access = Bind.bind_managed_value(name, __MODULE__)

          quote do
            unquote(managed_value_access) = unquote(decode_field(field, env))
          end

        end
      )

    read_by_calls =
      DecodeFunctionReadByCalls.read_by_calls(
        fields,
        registered_callbacks_map,
        __MODULE__
      )

    decoded_map_fields_with_values =
      Enum.map(
        fields,
        fn field ->

            case field do
              %Field{ name: name } ->

                { name, Bind.bind_managed_value(name, __MODULE__) }

              %VirtualField{ name: name, opts: opts } ->

                case opts[:read_by] do

                  read_by when not is_nil(read_by) ->

                    { name, Bind.bind_managed_value(name, __MODULE__) }

                  _ -> nil

                end

            end


      end)
      |> Enum.reject(&is_nil/1)


    quote do

      def decode(%__MODULE__{
        unquote_splicing(struct_fields)
      }) do

          unquote_splicing(managed_values_bindings)
          unquote_splicing(read_by_calls)

        %{
          unquote_splicing(decoded_map_fields_with_values)
        }

      end

    end

  end

end