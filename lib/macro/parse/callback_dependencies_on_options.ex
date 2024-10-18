defmodule BinStruct.Macro.Parse.CallbackDependenciesOnOptions do

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.Callback
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackNewArgument
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Structs.RegisteredOption
  alias BinStruct.Macro.Structs.InterfaceImplementation
  alias BinStruct.Macro.Parse.CallbacksOnField


  def option_dependencies_of_interface_implementation(%InterfaceImplementation{} = interface_implementation, registered_callbacks_map) do

    %InterfaceImplementation{ callback: callback } = interface_implementation

    option_dependencies([callback], registered_callbacks_map)

  end

  def option_dependencies_of_callbacks_on_fields(%Field{} = field, registered_callbacks_map) do

    callbacks_on_field = CallbacksOnField.callbacks(field)

    option_dependencies(callbacks_on_field, registered_callbacks_map)

  end

  def option_dependencies(callbacks, registered_callbacks_map) do


    Enum.map(
      callbacks,
      fn %Callback{} = callback ->

        registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, callback)

        %RegisteredCallback{ arguments: arguments } = registered_callback

        Enum.map(
          arguments,
          fn argument ->

            case argument do
              %RegisteredCallbackFieldArgument{} = _field_argument -> nil
              %RegisteredCallbackOptionArgument{} = option_argument -> option_argument
              %RegisteredCallbackNewArgument{} = _new_argument -> nil
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



end