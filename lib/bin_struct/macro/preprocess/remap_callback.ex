defmodule BinStruct.Macro.Preprocess.RemapCallback do

  @moduledoc false

  alias BinStruct.Macro.FunctionName

  def remap_callback(nil = _raw_callback, _env), do: nil

  def remap_callback(raw_callback, env) do

    raw_callback =
      if is_function_ref(raw_callback) do
        raw_callback
      else
        { ast, _bindings } = Code.eval_quoted(raw_callback, [], env)
        ast
      end

    case FunctionName.function_name(raw_callback, env) do

      function_name when function_name != :unknown ->

        arity = BinStruct.Macro.FunctionArity.function_arity(raw_callback, env)
       
        %BinStruct.Macro.Structs.Callback{
          function: raw_callback,
          function_name: function_name,
          function_arity: arity
        }

      :unknown -> raise "not a function reference (&), given: #{inspect(raw_callback)}"

    end

  end


  defp is_function_ref(raw_callback) do

    case raw_callback do
      {:&, _,
        [
          {:/, _,
            [{ _function_name, _, _}, _arity]}
        ]} -> true

      _ -> false
    end



  end

end