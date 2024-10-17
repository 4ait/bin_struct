defmodule BinStruct.Macro.Parse.BinaryMatchPatternKnownSize do

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.OneOfPack
  alias BinStruct.Macro.FieldSize
  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.OneOfPackName

  def binary_match_pattern_for_known_size_field_or_pack(field_or_pack, context) do

    case field_or_pack do

      %Field{} = field ->

        %Field{ name: name, type: type } = field

        value_access = { Bind.bind_value_name(name), [], context }

        case type do

          { :static_value, %{ value: value } } ->

            quote do
              unquote(value)
            end

          _ ->

            field_size_bits = FieldSize.field_size_bits(field)

            case Integer.mod(field_size_bits, 8) do

              0 ->

                field_size_bytes = Integer.floor_div(field_size_bits, 8)

                quote do
                  unquote(value_access)::(unquote(field_size_bytes)-bytes)
                end

              _ ->

                quote  do
                  unquote(value_access)::(unquote(field_size_bits)-bits)
                end

            end

        end

      %OneOfPack{} = pack ->

        pack_size_bits = FieldSize.pack_size_bits(pack)

        pack_name = OneOfPackName.one_of_pack_name(pack)

        pack_value_access = { Bind.bind_value_name(pack_name), [], context }

        case Integer.mod(pack_size_bits, 8) do

          0 ->

            field_size_bytes = Integer.floor_div(pack_size_bits, 8)

            quote do
              unquote(pack_value_access)::(unquote(field_size_bytes)-bytes)
            end

          _ ->

            quote  do
              unquote(pack_value_access)::(unquote(pack_size_bits)-bits)
            end

        end


    end



  end


end