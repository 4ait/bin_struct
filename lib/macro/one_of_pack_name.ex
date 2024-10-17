defmodule BinStruct.Macro.OneOfPackName do

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.OneOfPack

  def one_of_pack_name(%OneOfPack{} = pack) do

    %OneOfPack{ fields: fields_in_pack } = pack


    Enum.reduce(
      fields_in_pack,
      "",
      fn %Field{} = field_in_pack, acc ->

        %Field{ name: name } = field_in_pack


        case acc do
          "" -> Atom.to_string(name)
          acc ->

            acc <> "_or_" <> Atom.to_string(name)

        end


      end

    )

  end

end