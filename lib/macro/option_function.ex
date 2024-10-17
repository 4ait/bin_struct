defmodule BinStruct.Macro.OptionFunction do

  def option_function(name, _parameters, _env) do

    function_name = :"option_#{name}"

    quote do

      def unquote(function_name)(options \\ [], option_value) do

        new_option = { __MODULE__, unquote(name), option_value }

        [ new_option | options ]

      end

    end

  end

end