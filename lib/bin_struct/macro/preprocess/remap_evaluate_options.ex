defmodule BinStruct.Macro.Preprocess.RemapEvaluateOptions do

  @moduledoc false

  def remap_evaluate_options(opts, env) do

    opts
    |> Keyword.replace(
        :length,
         evaluate_expression(opts[:length])
    )

  end

  defp evaluate_expression(expression) do

    { result, bindings } = Code.eval_quoted(expression)

    result

  end

end
