defmodule BinStruct.Macro.ChildrenBinStructs do

  @moduledoc false

  alias BinStruct.Macro.Structs.Field

  def children_bin_structs(fields, _env) do

    Enum.map(
      fields,
      fn %Field{} = field ->

        %Field{ type: type } = field
        expand_type_children(type)

      end
    )
    |> List.flatten()

  end

  defp expand_type_children(type) do
    expand_type_children(type, [])
  end

  defp expand_type_children(type, acc) do


    case type do
      { :list_of, %{ item_type: item_type } = _list_info } ->

        expand_type_children(item_type, acc)
      { :module, %{ module_full_name: module_full_name } } -> [ module_full_name | acc ]
      { :variant_of, variants } ->
        Enum.map(
          variants,
          fn variant -> expand_type_children(variant, acc)  end
        )
      _ -> acc
    end

  end



end