defmodule BinStruct.Macro.ExpandOneOfPacksFields do

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.Structs.OneOfPack

  def expand_one_of_packs_fields(fields_or_one_of_packs) do

    Enum.map(
      fields_or_one_of_packs,
      fn field_or_one_of_pack ->

        case field_or_one_of_pack do
          %Field{} = field -> field
          %VirtualField{} = virtual_field -> virtual_field
          %OneOfPack{ fields: fields } -> fields
        end
      end
    )
    |> List.flatten()

  end

end