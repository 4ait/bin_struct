defmodule BinStruct.Macro.CallbacksOnField do

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap

  def callbacks_used_while_parsing(%Field{ opts: opts }, registered_callbacks_map) do

    [
      opts[:optional_by],
      opts[:length_by],
      opts[:count_by],
      opts[:item_size_by],
      opts[:take_while_by],
      opts[:validate_by],
    ]
    |> Enum.reject(&is_nil/1)
    |> registered_version_of_callbacks(registered_callbacks_map)

  end

  defp registered_version_of_callbacks(callbacks, registered_callbacks_map) do

      Enum.map(
        callbacks,
        fn callback ->
          RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, callback)
        end
      )

  end

end