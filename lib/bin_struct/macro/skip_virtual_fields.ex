defmodule BinStruct.Macro.NonVirtualFields do

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField

  def skip_virtual_fields(fields) do

    Enum.map(
      fields,
      fn field ->

        case field do
          %Field{} = field -> field
          %VirtualField{} = _virtual_field -> nil
        end
      end
    )
    |> Enum.reject(&is_nil/1)

  end

end