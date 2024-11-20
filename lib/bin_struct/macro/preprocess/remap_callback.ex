defmodule BinStruct.Macro.Preprocess.RemapCallback do

  @moduledoc false

  alias BinStruct.Macro.FunctionName

  def remap_callback(nil = _raw_callback, _env), do: nil

  def remap_callback(raw_callback, env) do

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

end