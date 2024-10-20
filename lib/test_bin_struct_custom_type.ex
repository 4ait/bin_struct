defmodule BinStructCustomType do


  defmacro __using__(_opts) do

    quote do
      @before_compile BinStructCustomType
    end

  end

  defmacro __before_compile__(_env) do


    result_quote =
      quote do

        def __default_options__(), do: %{}
        def __module_type__(), do: :bin_struct_custom_type

      end

    module_code = BinStruct.MacroDebug.code(result_quote)

    quote do

      unquote(result_quote)

      unquote(

        if Mix.env() != :prod do

          quote do

            def module_code() do
              code = unquote(module_code)
              IO.puts(code)
            end

          end

        end
      )

    end

  end

end