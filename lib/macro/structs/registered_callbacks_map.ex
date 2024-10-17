defmodule BinStruct.Macro.Structs.RegisteredCallbacksMap do

  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.Callback

  defstruct [
    :registered_callbacks_map
  ]

  def new(registered_callbacks, env) do
    %RegisteredCallbacksMap{
      registered_callbacks_map: registered_callbacks_make_map(registered_callbacks, env)
    }
  end

  def get_registered_callback_by_callback(self, %Callback{} = callback) do

    %{ registered_callbacks_map: registered_callbacks_map } = self

    %Callback{ function_name: function_name, function_arity: function_arity } = callback

    key = { function_name, function_arity }

    if !Map.has_key?(registered_callbacks_map, key) do
      raise "Registered callback #{function_name} with arity #{function_arity} does not exists."
    end

    %{ ^key => registered_callback } = registered_callbacks_map

    registered_callback

  end


  defp registered_callbacks_make_map(registered_callbacks, env) do

    Enum.map(
      registered_callbacks,
      fn %RegisteredCallback{} = registered_callback ->

        %RegisteredCallback{ function: function } = registered_callback

        function_name = BinStruct.Macro.FunctionName.function_name(function, env)
        arity = BinStruct.Macro.FunctionArity.function_arity(function, env)

        key = { function_name, arity }

        { key, registered_callback }

      end
    ) |> Enum.into(%{})

  end

end
