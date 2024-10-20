defmodule BinStruct.Macro.DumpBinaryFunction do

  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.IsOptionalField

  def dump_binary_function(fields, _env) do

    dump_fields =
      Enum.map(
        fields,
        fn %Field{} = field ->

          encoded = encode_field_for_dump(field)

          size_bits = BinStruct.Macro.FieldSize.field_size_bits(field)

          case size_bits do
            size_bits when size_bits != :unknown  ->

              is_bit_size = size_bits < 8 || Integer.mod(size_bits, 8) > 0

              if is_bit_size do

                quote do
                  unquote(encoded)::bitstring
                end

              else
                quote do
                  unquote(encoded)::binary
                end
              end

            :unknown ->

              quote do
                unquote(encoded)::binary
              end

          end



        end
      )

    static_not_optional_fields =
      Enum.filter(
        fields,
        fn %Field{} = field ->

          %Field{ type: type } = field

          is_optional = IsOptionalField.is_optional_field(field)

          case type do
            { :static_value, _ } when not is_optional -> true
            _ -> false
          end

        end
      )

    struct_deconstruction_fields =
      Enum.map(
        fields -- static_not_optional_fields,
        fn %Field{} = field ->

          %Field{name: name} = field

          { name, { Bind.bind_value_name(name), [], __MODULE__ } }
        end
      ) |> Keyword.new()

    quote do

      def dump_binary(%__MODULE__{
        unquote_splicing(struct_deconstruction_fields)
      }) do
        <<unquote_splicing(dump_fields)>>
      end

    end


  end

  def encode_type_for_dump(value_access, type, opts, is_optional) do

    length = opts[:length]

    expr =
      case type do

        { :enum, %{ type: enum_representation_type } } ->

          encode_type_for_dump(
            value_access,
            enum_representation_type,
            opts,
            is_optional
          )

        { :flags, %{ type: flags_representation_type } } ->

          encode_type_for_dump(
            value_access,
            flags_representation_type,
            opts,
            is_optional
          )

        {:list_of, %{ item_type: item_type } } ->

          item_access = { :item, [], __MODULE__ }
          item_encode_expr = encode_type_for_dump(item_access, item_type, opts, false)

          quote do

            Enum.reduce(
              unquote(value_access),
              _bin_acc = <<>>,
              fn item, bin_acc ->

                 unquote(item_access) = unquote(item_encode_expr)

                 bin_acc <> unquote(item_access)

              end
            )

          end

        {:module, module_info } -> dump_module(module_info, value_access)

        {:variant_of, variants } ->

          patterns =
            Enum.map(
              variants,
              fn variant ->

                { :module, module_info }  = variant

                %{ module_full_name: module_full_name } = module_info

                left =
                  quote do
                    %unquote(module_full_name){} = unquote(value_access)
                  end

                right = dump_module(module_info, value_access)

                BinStruct.Macro.Common.case_pattern(left, right)

              end
            )

          quote do

            case unquote(value_access) do
              unquote(patterns)
            end

          end


        {:static_value, %{value: value} } ->

            quote do
              unquote(value)
            end

        :binary when is_integer(length) -> value_access

        :binary -> value_access

        { :uint, _typedef }->  value_access
        { :int, _typedef } ->  value_access

        { :bool, _info } -> value_access

        :uint8 -> value_access
        :int8 -> value_access

        :uint16_be -> value_access
        :uint32_be -> value_access
        :uint64_be -> value_access
        :int16_be -> value_access
        :int32_be -> value_access
        :int64_be -> value_access
        :float32_be -> value_access
        :float64_be -> value_access

        :uint16_le -> value_access
        :uint32_le -> value_access
        :uint64_le -> value_access
        :int16_le -> value_access
        :int32_le -> value_access
        :int64_le -> value_access
        :float32_le -> value_access
        :float64_le -> value_access

      end


      if is_optional do

         quote do


           case unquote(value_access) do
             nil -> <<>>
             _ -> unquote(expr)
           end

         end

      else
        expr
      end


  end

  defp encode_field_for_dump(%Field{} = field) do

    %Field{name: name, type: type, opts: opts} = field

    name_field = { Bind.bind_value_name(name), [], __MODULE__}

    is_optional = IsOptionalField.is_optional_field(field)

    encode_type_for_dump(name_field, type, opts, is_optional)

  end

  defp dump_module(module_info, value_access) do

    case module_info do
      %{ module_type: :bin_struct, module: module } ->

        quote do
          unquote(module).dump_binary(unquote(value_access))
        end

      %{
        module_type: :bin_struct_custom_type,
        module: module,
        custom_type_args: custom_type_args
      } ->

        quote do
          unquote(module).dump_binary(unquote(value_access), unquote(custom_type_args))
        end

    end




  end



end