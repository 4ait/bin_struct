defmodule BinStruct.Macro.Common do

  def case_pattern(left, right) do
    {:->, [], [[left], right] }
  end

end