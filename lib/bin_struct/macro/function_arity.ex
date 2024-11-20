defmodule BinStruct.Macro.FunctionArity do

  @moduledoc false

  def function_arity(function, _env) do

    case function do

      #when is function reference
      {:&, _,
        [
          {:/, _,
            [{ _function_name, _, _}, arity]}
        ]} ->

        arity

      #when is anonymous function
      _function -> :unknown

    end

  end



end