defmodule BinStruct.Macro.Parse.CallbacksOnField do

  alias BinStruct.Macro.Structs.Field

  def callbacks(%Field{ opts: opts}) do

    [
      opts[:one_of_by],
      opts[:optional_by],
      opts[:length_by],
      opts[:count_by],
      opts[:item_size_by],
      opts[:take_while_by],
      opts[:validate_by]
    ] |> Enum.reject(&is_nil/1)

  end

end