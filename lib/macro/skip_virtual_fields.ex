defmodule BinStruct.Macro.NonVirtualFields do

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.Structs.OneOfPack

  def skip_virtual_fields(fields_or_one_of_packs) do

    Enum.map(
      fields_or_one_of_packs,
      fn field_or_one_of_pack ->

        case field_or_one_of_pack do
          %Field{} = field -> field
          %VirtualField{} = _virtual_field -> nil
          %OneOfPack{} = one_of_pack -> one_of_pack
        end
      end
    )
    |> Enum.reject(&is_nil/1)

  end

end