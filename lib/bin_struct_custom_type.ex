defmodule BinStructCustomType do

  @moduledoc """
  `BinStructCustomType` is user defined type when you need most control of how data are parsed.

  Such custom type can be used in place you would use BinStruct.

  The only currently limitation it can't be used directly inside variant_of (variant_of dispatching relays on elixir struct).

  Required functions to be defined by custom type:

  * either `parse_returning_options/3` or `parse_exact_returning_options/3`
  * `size/2`
  * `known_total_size_bytes/2`
  * `dump_binary/2`
  * `from_unmanaged_to_managed/2`
  * `from_managed_to_unmanaged/2`

  Optional functions to be defined by custom type:

  * `init_args/1`

  ## Basic Example

  ```elixir
  defmodule SimpleCustomTypeTwoBytesLong do
    use BinStructCustomType

    def parse_returning_options(bin, _custom_type_args, opts) do
      case bin do
        <<data::2-bytes, rest::binary>> -> {:ok, data, rest, opts}
        _ -> :not_enough_bytes
      end
    end

    def size(_data, _custom_type_args), do: 2
    def known_total_size_bytes(_custom_type_args), do: 2
    def dump_binary(data, _custom_type_args), do: data
    def from_unmanaged_to_managed(unmanaged, _custom_type_args), do: unmanaged
    def from_managed_to_unmanaged(managed, _custom_type_args), do: managed
  end
  ```
  """

  alias BinStruct.Macro.OptionFunction
  alias BinStruct.Macro.Structs.RegisteredOptionsMap
  alias BinStruct.Macro.Preprocess.RemapRegisteredOption

  defmacro __using__(_opts) do

    Module.register_attribute(__CALLER__.module, :options, accumulate: true)

    quote do
      import BinStructCustomType
      @before_compile BinStructCustomType
    end

  end


  @doc """
  Registering option for custom type. Interface will be your module name.
  Implementation and usage same as register_option for BinStruct.

  See more in `BinStruct.register_option/2`
  """

  defmacro register_option(name, parameters \\ []) do
    raw_registered_option = { name, parameters }
    Module.put_attribute(__CALLER__.module, :options, raw_registered_option)
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

    raw_registered_options = Module.get_attribute(env.module, :options) |> Enum.reverse()

    registered_options =
      Enum.map(
        raw_registered_options,
        fn raw_option ->
          RemapRegisteredOption.remap_raw_registered_option(raw_option, env)
        end
      )

    registered_options_map =
      RegisteredOptionsMap.new(
        registered_options,
        env
      )

    option_functions =
      Enum.map(
        raw_registered_options,
        fn { name, parameters } ->
          OptionFunction.option_function(name, parameters, env)
        end
      )

    registered_options_map_access_function =

      quote do
        def __registered_options_map__() do

          unquote(
            Macro.escape(registered_options_map)
          )

        end

      end

    options_default_values_function =
      BinStruct.Macro.AllDefaultOptionsFunction.default_options_function(registered_options, env)

    result_quote =
      quote do

        unquote(registered_options_map_access_function)
        unquote_splicing(option_functions)

        unquote(options_default_values_function)

        def __module_type__(), do: :bin_struct_custom_type

        unquote_splicing(
          maybe_auto_implementation_of_parse_exact_returning_options(
            is_parse_returning_options_defined && !is_parse_exact_returning_options_defined
          )
        )

      end

    module_code = BinStruct.Macro.MacroDebug.code(result_quote)

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

    if !Module.defines?(module, {:size, 2}) do
      raise "Custom type required to define size/2"
    end

    if !Module.defines?(module, {:known_total_size_bytes, 1}) do
      raise "Custom type required to define known_total_size_bytes/2"
    end

    if !Module.defines?(module, {:dump_binary, 2}) do
      raise "Custom type required to define dump_binary/2"
    end

    if !Module.defines?(module, {:from_unmanaged_to_managed, 2}) do
      raise "Custom type required to define from_unmanaged_to_managed/2"
    end

    if !Module.defines?(module, {:from_managed_to_unmanaged, 2}) do
      raise "Custom type required to define from_managed_to_unmanaged/2"
    end



  end

end
