defmodule BinStruct.Macro.FunctionName do

  def function_name(function, _env) do

    case function do

      #when is function reference
      {:&, _,
        [
          {:/, _,
            [{ function_name, _, _}, _arity]}
        ]} ->

        function_name

      #when is anonymous function
      _function -> :unknown

    end

  end



end