defmodule BinStructOptionsInterface do

  alias BinStruct.Macro.OptionFunction
  alias BinStruct.Macro.Preprocess.RemapRegisteredOption
  alias BinStruct.Macro.Structs.RegisteredOptionsMap

  defmacro __using__(_opts) do

    quote do
      import BinStructOptionsInterface
    end

  end

  defmacro register_option(_name, _parameters \\ []) do
      raise "should not be called directly, wrap with register_options_interface block"
  end

  defp remap_register_option_call_to_raw_option(register_option_call) do

    { :register_option, _, args } = register_option_call

    case args do
      [ name ] -> { name, [] }
      [ name, parameters ] -> { name, parameters }
    end

  end

  defmacro register_options_interface([do: block]) do

    env = __CALLER__

    raw_options =
      case block do
        { :__block__, _meta, register_option_calls } ->

            Enum.map(
              register_option_calls,
              fn register_option_call  ->
                remap_register_option_call_to_raw_option(register_option_call)
              end
            )

        { :register_option, _, _ } = register_option_call -> [ remap_register_option_call_to_raw_option(register_option_call) ]
      end


    registered_options =
      Enum.map(
        raw_options,
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
        raw_options,
        fn { name, parameters } ->
          OptionFunction.option_function(name, parameters, env)
        end
     )


    result_quote =
      quote do

        unquote(registered_options_map_access_function)

        unquote_splicing(option_functions)
      end


    module_code = BinStruct.MacroDebug.code(result_quote)

    quote do

      unquote(result_quote)

      def module_code() do
        code = unquote(module_code)
        IO.puts(code)
      end

    end

  end


end