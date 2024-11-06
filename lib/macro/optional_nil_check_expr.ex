defmodule BinStruct.Macro.OptionalNilCheckExpression do

  def maybe_wrap_optional(output, input, is_optional) do

    if is_optional do
      wrap_optional(output, input)
    else
      output
    end

  end

  def wrap_optional(output, input) do

    quote do

      case unquote(input) do
        nil -> nil
        unquote(input) -> unquote(output)
      end

    end

  end


end