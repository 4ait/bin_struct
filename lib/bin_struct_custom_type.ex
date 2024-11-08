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


    ensure_custom_type_has_required_function_defined(env.module)

    is_parse_returning_options_defined = Module.defines?(env.module, {:parse_returning_options, 3})
    is_parse_exact_returning_options_defined = Module.defines?(env.module, {:parse_exact_returning_options, 3})

    result_quote =
      quote do

        def __default_options__(), do: %{}
        def __module_type__(), do: :bin_struct_custom_type

        unquote_splicing(
          maybe_auto_implementation_of_parse_exact_returning_options(
            is_parse_returning_options_defined && !is_parse_exact_returning_options_defined
          )
        )

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


  defp ensure_custom_type_has_required_function_defined(module) do

    parse_returning_options = Module.defines?(module, {:parse_returning_options, 3})

    parse_exact_returning_options = Module.defines?(module, {:parse_exact_returning_options, 3})

    if !parse_returning_options && !parse_exact_returning_options  do
      raise "Custom type required to define either parse_returning_options/3 or parse_exact_returning_options/3 or both"
    end

    if !Module.defines?(module, {:dump_binary, 2}) do
      raise "Custom type required to define dump_binary/2"
    end

    if !Module.defines?(module, {:size, 2}) do
      raise "Custom type required to define size/2"
    end

    if !Module.defines?(module, {:from_unmanaged_to_managed, 2}) do
      raise "Custom type required to define from_unmanaged_to_managed/2"
    end

    if !Module.defines?(module, {:from_managed_to_unmanaged, 2}) do
      raise "Custom type required to define from_managed_to_unmanaged/2"
    end

    if !Module.defines?(module, {:known_total_size_bytes, 1}) do
      raise "Custom type required to define known_total_size_bytes/2"
    end


  end

end