defmodule BinStructOptionsInterface do

  @moduledoc """
  ```elixir
  iex> defmodule SharedOptions do
  ...>   use BinStructOptionsInterface
  ...>
  ...>   @type runtime_context1 :: :context_a
  ...>   @type runtime_context2 :: :context_b
  ...>
  ...>   register_option :runtime_context1
  ...>   register_option :runtime_context2
  ...>
  ...> end
  ...>
  ...> SharedOptions.option_runtime_context1(:context_a)
  ...> |> SharedOptions.option_runtime_context2(:context_b)
  ```
  """

  alias BinStruct.Macro.OptionFunction
  alias BinStruct.Macro.Preprocess.RemapRegisteredOption
  alias BinStruct.Macro.Structs.RegisteredOptionsMap

  defmacro __using__(_opts) do

    Module.register_attribute(__CALLER__.module, :options, accumulate: true)

    quote do
      import BinStructOptionsInterface
      @before_compile BinStructOptionsInterface

    end

  end

  @doc """
  Registering option for option interface. Interface will be your module name.
  Implementation and usage same as `register_option` for `BinStruct`.

  See more in `BinStruct.register_option/2`
  """

  defmacro register_option(name, parameters \\ []) do

    raw_registered_option = { name, parameters }

    Module.put_attribute(__CALLER__.module, :options, raw_registered_option)
  end

  defmacro __before_compile__(env) do

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

    registered_options_map_access_function =

      quote do
        def __registered_options_map__() do

          unquote(
            Macro.escape(registered_options_map)
          )

        end

      end

    option_functions =
      Enum.map(
        raw_registered_options,
        fn { name, parameters } ->
          OptionFunction.option_function(name, parameters, env)
        end
      )


    result_quote =
      quote do
        unquote(registered_options_map_access_function)
        unquote_splicing(option_functions)
      end


    module_code = BinStruct.Macro.MacroDebug.code(result_quote)

    quote do

      unquote(result_quote)

      def module_code() do
        code = unquote(module_code)
        IO.puts(code)
      end

    end

  end


end
