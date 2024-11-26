defmodule BinStruct.Macro.Decode.DecodeFunction do

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


  def decode_type(type, _opts, value_access, deep_access) do

      case type do

        { :variant_of, variants } ->

          patterns =
            Enum.map(
              variants,
              fn variant ->

                { :module, module_info }  = variant

                if module_info[:module_type] == :bin_struct_custom_type do

                  raise "decode of custom type as variant argument not implemented"

                end

                %{ module_full_name: module_full_name } = module_info

                left =
                  quote do
                    %unquote(module_full_name){} = module
                  end

                right =
                  quote do
                    unquote(module_full_name).decode(module, deep: true)
                  end

                BinStruct.Macro.Common.case_pattern(left, right)

              end
            )

          quote do

            case unquote(deep_access) do
              true ->

                case unquote(value_access) do
                  unquote(patterns)
                end


              false -> unquote(value_access)

            end

          end

        { :module, module_info } ->

          case module_info do

            %{
              module_type: :bin_struct,
              module: module
            } ->

              quote do

                case unquote(deep_access) do
                  true -> unquote(module).decode(unquote(value_access), deep: true)
                  false -> unquote(value_access)
                end

              end

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
              module: module
            } ->

              quote do

                case unquote(deep_access) do
                  true ->
                    Enum.map(
                      unquote(value_access),
                      fn item ->
                        unquote(module).decode(item, deep: true)
                      end
                    )
                  false -> unquote(value_access)
                end

              end

            %{
              module_type: :bin_struct_custom_type,
              module: module,
              custom_type_args: custom_type_args
            } ->

              quote do

                case unquote(deep_access) do
                  true ->
                    Enum.map(
                      unquote(value_access),
                      fn item ->
                        unquote(module).decode(item, unquote(custom_type_args), deep: true)
                      end
                    )
                  false -> unquote(value_access)
                end

              end

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

    deep_access = { :deep, [], __MODULE__ }

    decode_type_expr = decode_type(type, opts, unmanaged_value_access, deep_access)

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
      }, opts \\ []) do

        deep =
          case opts[:deep] do
            nil -> false
            value when is_boolean(value) -> value
          end

          unquote_splicing(managed_values_bindings)

          unquote_splicing(read_by_calls)

        %{
          unquote_splicing(decoded_map_fields_with_values)
        }

      end

    end

  end

end