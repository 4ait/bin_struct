defmodule BinStruct.Macro.Preprocess.RemapStaticValue do

  @moduledoc false

  def remap_static_value(static_value, opts, env) do

    case static_value do

      {:<<>>, _meta, _value } ->

        size_bits_ast =

          quote do

            bit_size(
              unquote(static_value)
            )

          end

        { size_bits, _binding } = Code.eval_quoted(size_bits_ast, [], env)


        {
          :static_value,
          %{
            value: static_value,
            size_bits: size_bits
          }
        }

      static_value when is_binary(static_value) or is_bitstring(static_value) ->

        size_bits = bit_size(static_value)

        {
          :static_value,
          %{
            value: static_value,
            size_bits: size_bits
          }
        }

      { :static, ast }  ->

        { result, _binding } = Code.eval_quoted(ast, [], env)

        remap_static_value(result, opts, env)

    end

  end


end