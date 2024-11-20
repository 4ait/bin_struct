defmodule BinStruct.Macro.Common do

  @moduledoc false

  def case_pattern(left, right) do
    {:->, [], [[left], right] }
  end

end