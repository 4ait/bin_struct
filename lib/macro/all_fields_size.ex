defmodule BinStruct.Macro.AllFieldsSize do

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.OneOfPack
  alias BinStruct.Macro.FieldSize
  alias BinStruct.Macro.Utils

  def get_all_fields_and_packs_size_bytes(fields_or_packs) do

    size_in_bits =
      Enum.reduce_while(
        fields_or_packs,
        _size_in_bits = 0,
        fn field_or_pack, acc ->

          case field_or_pack do
            %Field{} = field ->

              field_size_in_bits = FieldSize.field_size_bits(field)

              case field_size_in_bits do
                field_size_in_bits when is_integer(field_size_in_bits) -> { :cont, acc + field_size_in_bits }
                :unknown -> { :halt, :unknown }
              end


            %OneOfPack{} = one_of_pack ->
              case FieldSize.pack_size_bits(one_of_pack) do

                pack_size_bits when is_integer(pack_size_bits) -> { :cont, acc + pack_size_bits }

                :different_size -> raise "all fields of pack #{inspect(one_of_pack)} should be equal in size"
                :unknown -> raise "fall fields of pack #{inspect(one_of_pack)} should have known size"
              end

          end

        end
      )

    Utils.bit_size_to_byte_size(size_in_bits)

  end


end