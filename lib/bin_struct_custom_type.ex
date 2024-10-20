defmodule BinStructCustomType do


  defmacro __using__(_opts) do

    quote do
      @before_compile BinStructCustomType
    end

  end

  defp maybe_auto_implementation_of_parse_exact_returning_options(is_custom_type_terminated) do

    impl =
      if is_custom_type_terminated do

          quote do

            def parse_exact_returning_options(bin, custom_type_args, options \\ nil) do

              case parse_returning_options(bin, custom_type_args, options) do
                { :ok, parsed, "", options } -> { :ok, parsed, options }
                { :ok, _parsed, non_empty_binary, _options } -> raise "non empty binary left after parse exact call #{inspect(non_empty_binary)}"
                { :wrong_data, _wrong_data } = wrong_data_clause -> wrong_data_clause
                :not_enough_bytes -> raise "not_enough_bytes returned from parse exact"
              end

            end

          end

      end

    case impl do
      nil -> []
      impl -> [impl]
    end

  end

  defmacro __before_compile__(env) do


    result_quote =
      quote do

        def __default_options__(), do: %{}
        def __module_type__(), do: :bin_struct_custom_type

      end

    module_code = BinStruct.MacroDebug.code(result_quote)

    is_custom_type_terminated = BinStruct.Macro.Termination.is_bin_struct_custom_type_terminated(env.module)

    quote do

      unquote(result_quote)

      unquote_splicing(
        maybe_auto_implementation_of_parse_exact_returning_options(is_custom_type_terminated)
      )

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