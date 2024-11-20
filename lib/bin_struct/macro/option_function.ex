defmodule BinStruct.Macro.OptionFunction do

  @moduledoc false

  def option_function(name, _parameters, _env) do

    function_name = :"option_#{name}"

    quote do

      def unquote(function_name)(options \\ [], option_value)

      def unquote(function_name)(options, option_value) when is_list(options) do

        new_option = { __MODULE__, unquote(name), option_value }

        [ new_option | options ]

      end

      def unquote(function_name)(options_map, option_value) when is_map(options_map) do

        interface = __MODULE__
        name = unquote(name)

        %{
          ^interface => options_in_interface
        } = options_map

        %{
          options_map |
          interface => %{
            options_in_interface |
            name => option_value
          }
        }

      end

    end

  end

end