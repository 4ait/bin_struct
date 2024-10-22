defmodule BinStruct.Macro.DumpBinaryFunction do

  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.IsOptionalField
  alias BinStruct.Macro.TypeConverterToBinary
  alias BinStruct.Macro.FieldSize

  def dump_binary_function(fields, _env) do

    dump_fields =
      Enum.map(
        fields,
        fn field ->

          %Field{ name: name, type: type } = field

          unmanaged_value_access = Bind.bind_unmanaged_value(name, __MODULE__)

          is_optional = IsOptionalField.is_optional_field(field)


          #unquote(encoded)::bitstring

          to_binary_value_expression =  TypeConverterToBinary.convert_unmanaged_value_to_binary(type, unmanaged_value_access)

          encoded =
            if is_optional do
              quote do

                case unquote(unmanaged_value_access) do
                  nil -> <<>>
                  nil -> unquote(to_binary_value_expression)
                end

              end
            else
              to_binary_value_expression
            end



          case FieldSize.field_size_bits(field) do

            :unknown ->

              quote do
                unquote(encoded)::binary
              end

            bit_size ->

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

          { name, Bind.bind_unmanaged_value(name, __MODULE__) }

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


end