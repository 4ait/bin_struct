defmodule BinStruct.Macro.SizeFunction do

  alias BinStruct.Macro.FieldSize
  alias BinStruct.Macro.AllFieldsSize
  alias BinStruct.Macro.BitSizeConverter
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.OneOfPack


  def size_function(fields_and_packs, _env) do

    { known_size_fields_and_packs, unknown_size_fields } = split_known_size_and_unknown_size_fields_and_packs(fields_and_packs)

    map_fields =
      Enum.map(
        unknown_size_fields,
        fn %Field{} = field ->

          %Field{name: name} = field

          value_access = { name, [], __MODULE__ }
          { name, value_access }
        end
      )

    static_size = AllFieldsSize.get_all_fields_and_packs_size_bytes(known_size_fields_and_packs)

    size =
      Enum.reduce(
        unknown_size_fields,
        _size_acc = static_size,
        fn %Field{} = field, acc ->


          %Field{name: name, type: type, opts: opts} = field

          field_access = { name, [], __MODULE__ }

          is_optional = BinStruct.Macro.IsOptionalField.is_optional_field(field)

          size_expr = unknown_size_type_size_expr(type, field_access, opts, is_optional)

          size_expr_wrap_maybe_optional(size_expr, field_access, is_optional)
          |> size_expr_wrap_acc(acc)

        end
      )

    quote do

      def size(%__MODULE__{
        unquote_splicing(map_fields)
      }) do
        unquote(size)
      end

    end

  end


  defp size_expr_wrap_maybe_optional(size_expr, field_access, is_optional) do

    if is_optional do
      size_expr_wrap_optional(size_expr, field_access)
    else
      size_expr
    end

  end

  defp size_expr_wrap_optional(size_expr, field_access) do

    quote do

      case unquote(field_access) do
        nil -> 0
        _ -> unquote(size_expr)
      end

    end

  end

  defp size_expr_wrap_acc(size_expr, acc) do

    quote do
      unquote(acc) + unquote(size_expr)
    end

  end


  defp split_known_size_and_unknown_size_fields_and_packs(fields_and_packs) do

    Enum.reduce(
      fields_and_packs,
      { _known_size_fields_with_size = [], _unknown_size_fields = [] },
      fn field_or_pack, acc ->

        { known_size_fields, unknown_size_fields } = acc

        case field_or_pack do
          %Field{} = field ->

            is_optional = BinStruct.Macro.IsOptionalField.is_optional_field(field)

            case FieldSize.field_size_bits(field) do
              size when is_integer(size) and not is_optional -> { [field | known_size_fields], unknown_size_fields }
              _ -> { known_size_fields, [ field | unknown_size_fields] }
            end

          %OneOfPack{} = pack -> { [ pack | known_size_fields ], unknown_size_fields }

        end

      end
    )
    |> then(
         fn { known_size_fields, unknown_size_fields } ->
           { Enum.reverse(known_size_fields), Enum.reverse(unknown_size_fields) }
         end
       )

  end

  defp size_type_size_expr(type, field_access, opts, is_optional) do

    is_primitive_type = BinStruct.Macro.IsPrimitiveType.is_primitive_type(type)

    if is_primitive_type do

      FieldSize.type_size_bits(type, [])
      |> BitSizeConverter.bit_size_to_byte_size()

    else
      unknown_size_type_size_expr(type, field_access, opts, is_optional)
    end

  end

  defp unknown_size_type_size_expr(type, field_access, opts, is_optional) do

    termination = opts[:termination]
    length = opts[:length]

    case type do

      #need to figure out what is size of array at this point
      #array could contain raw values or structs, maybe just take all binaries by item type
      {:list_of, %{ item_type: item_type } } ->

         bind_item = { :item, [], __MODULE__ }

         quote do

           Enum.reduce(
             unquote(field_access),
             0,
             fn unquote(bind_item), acc ->

               acc + unquote(
                 size_type_size_expr(item_type, bind_item, opts, false)
               )

             end
           )

         end


      {:variant_of, variants } ->

          patterns =
            Enum.map(
              variants,
              fn variant ->


                { :module, %{ module_full_name: module_full_name} }  = variant

                left =
                  quote do
                    %unquote(module_full_name){}
                  end

                 right =
                  quote do
                    unquote(module_full_name).size(unquote(field_access))
                  end

                 BinStruct.Macro.Common.case_pattern(left, right)

              end
            )

          quote do

            case unquote(field_access) do
               unquote(patterns)
            end

          end

      {:module, %{module: module} } ->

          quote do
            unquote(module).size(unquote(field_access))
          end

      { :asn1, _asn1_info } ->

        quote do

          %{ binary: binary } = unquote(field_access)

          byte_size(binary)

        end

      _type when is_integer(length) ->

          quote do
            unquote(length)
          end


      :binary when not is_nil(termination) ->

          quote do
            byte_size(unquote(field_access)) + byte_size(unquote(termination))
          end

      :binary ->

          quote do
            byte_size(unquote(field_access))
          end

      _optional_type_of_known_size when is_optional ->

        size_bits = FieldSize.type_size_bits(type, opts)

        size_bytes =
          case Integer.mod(size_bits, 8) do
            0 -> Integer.floor_div(size_bits, 8)
            #_ -> raise "invalid bitsize of module. Size: #{size_bits} could not be packed into byte struct"
          end

        quote do
          unquote(size_bytes)
        end

    end

  end

end