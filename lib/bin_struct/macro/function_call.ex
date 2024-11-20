defmodule BinStruct.Macro.FunctionCall do

  @moduledoc false

  def function_call(function, args) do

    case function do

      #when is function reference
      {:&, _,
        [
          {:/, _,
            [{ function_name, _, _}, _function_arity]}
        ]} ->

        quote do
          unquote(function_name)(unquote_splicing(args))
        end

      #when is anonymous function

      function ->
        quote do
          unquote(function).(unquote_splicing(args))
        end
    end

  end



end