defmodule BinStruct.Macro.DecodeFunction do


  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Encoder
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.NonVirtualFields
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.RegisteredCallbackFunctionCall

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

                { :module, %{ module_full_name: module_full_name } }  = variant

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

        { :module, %{ module_full_name: module_full_name } } ->

          quote do

            case unquote(deep_access) do
              true -> unquote(module_full_name).decode(unquote(value_access), deep: true)
              false -> unquote(value_access)
            end

          end

        { :list_of, %{ item_type: {:module, %{ module_full_name: item_module_full_name }} } } ->

          quote do

            case unquote(deep_access) do
              true ->
                Enum.map(
                  unquote(value_access),
                  fn item ->
                    unquote(item_module_full_name).decode(item, deep: true)
                  end
                )
              false -> unquote(value_access)
            end

          end

        { :list_of, %{ item_type: item_type } } ->

          quote do

            Enum.map(
              unquote(value_access),
              fn unquote(value_access) ->
                unquote(Encoder.decode_bin_struct_field_to_term(item_type, value_access))
              end
            )

          end

        type -> Encoder.decode_bin_struct_field_to_term(type, value_access)

      end



  end

  defp decode_field(%Field{} = field, _env) do

    %Field{ name: name, type: type, opts: opts} = field

    value_access = { Bind.bind_value_name(name), [], __MODULE__ }
    deep_access = { :deep, [], __MODULE__ }

    decode_type_expr = decode_type(type, opts, value_access, deep_access)

    is_optional = BinStruct.Macro.IsOptionalField.is_optional_field(field)

    if is_optional do
      decode_expr_wrap_optional(decode_type_expr, value_access)
    else
      decode_type_expr
    end

  end

  defp decode_virtual_field(%VirtualField{} = virtual_field, registered_callbacks_map, _env) do

    %VirtualField{ type: type, opts: opts } = virtual_field

    read_by = opts[:read_by]

    read_by_registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, read_by)

    read_by_registered_callback_call = RegisteredCallbackFunctionCall.registered_callback_function_call(read_by_registered_callback, __MODULE__)

    value_access = { :value, [], __MODULE__ }
    deep_access = { :deep, [], __MODULE__ }

    decode_type_expr = decode_type(type, opts, value_access, deep_access)

    is_optional =
      case opts[:optional] do
        optional when is_boolean(optional) -> optional
        _ -> false
      end

    decode_type_expr_with_maybe_empty_binary_check =
      if is_optional do
        decode_expr_wrap_empty_binary(decode_type_expr, value_access)
      else
        decode_type_expr
      end

    quote do
      unquote(value_access) = unquote(read_by_registered_callback_call)
      unquote(decode_type_expr_with_maybe_empty_binary_check)
    end


  end

  def decode_function(fields, registered_callbacks_map, env) do

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

    struct_fields =
      Enum.map(
        non_virtual_fields,
        fn %Field{} = field ->

          %Field{ name: name } = field
           
          value_access = { Bind.bind_value_name(name), [], __MODULE__ }

          { name, value_access }

        end
      )

    fields_to_decode =  non_virtual_fields ++ virtual_fields_with_defined_read_by_callback

    decoded_values =
      Enum.map(
        fields_to_decode,
        fn field ->

          case field do
            %Field{ name: name } = field ->

              value_access = { Bind.bind_value_name(name), [], __MODULE__ }

              quote do
                unquote(value_access) = unquote(decode_field(field, env))
              end

            %VirtualField{ name: name } = virtual_field ->

              value_access = { Bind.bind_value_name(name), [], __MODULE__ }

              quote do
                unquote(value_access) = unquote(decode_virtual_field(virtual_field, registered_callbacks_map, env))
              end

          end

        end
      )

    map_fields_with_decoded_values =

      Enum.map(
        fields_to_decode,
        fn field ->

          opts =
            case field do
              %Field{ opts: opts } -> opts
              %VirtualField{  opts: opts } -> opts
            end

          case opts[:show_on_decode] do
            false -> nil
            _ ->

              case field do
                %Field{ name: name } ->

                  value_access = { Bind.bind_value_name(name), [], __MODULE__ }

                  { name, value_access }

                %VirtualField{ name: name } ->

                  value_access = { Bind.bind_value_name(name), [], __MODULE__ }

                  { name, value_access }

              end

          end

        end
      ) |> Enum.reject(&is_nil/1)


    quote do

      def decode(%__MODULE__{
        unquote_splicing(struct_fields)
      }, opts \\ []) do

        deep =
          case opts[:deep] do
            nil -> false
            value when is_boolean(value) -> value
          end

        unquote_splicing(decoded_values)

        %{
          unquote_splicing(map_fields_with_decoded_values)
        }

      end

    end

  end

end