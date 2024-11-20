defmodule BinStruct.Macro.MacroDebug do

  @moduledoc false

  def code(ast) do

    Macro.to_string(ast)
    |> Code.format_string!()

  end

  def puts_code(ast) do

    code(ast)
    |> IO.puts()

  end

end


