defmodule BinStruct.Macro.Parse.CallbackDependenciesOnOptions do

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.Callback
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Structs.RegisteredOption
  alias BinStruct.Macro.Structs.InterfaceImplementation
  alias BinStruct.Macro.Parse.CallbacksOnField


  alias BinStruct.Macro.CallbacksOnField

  def option_dependencies_of_interface_implementation(%InterfaceImplementation{} = interface_implementation, registered_callbacks_map) do

    %InterfaceImplementation{ callback: callback } = interface_implementation



    option_dependencies([callback], registered_callbacks_map)

  end

  def option_dependencies_of_callbacks_on_fields(%Field{} = field, registered_callbacks_map) do

    registered_callbacks = CallbacksOnField.callbacks_used_while_parsing(field, registered_callbacks_map)

    option_dependencies(registered_callbacks)

  end

  def option_dependencies(registered_callbacks) do

    Enum.map(
      registered_callbacks,
      fn registered_callback ->

        %RegisteredCallback{ arguments: arguments } = registered_callback

        Enum.map(
          arguments,
          fn argument ->

            case argument do
              %RegisteredCallbackFieldArgument{} = _field_argument -> nil
              %RegisteredCallbackOptionArgument{} = option_argument -> option_argument
            end

          end
        )
      end
    )
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.dedup_by(
         fn %RegisteredCallbackOptionArgument{registered_option: registered_option} ->
           %RegisteredOption{ name: name } = registered_option
           name
         end
       )

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