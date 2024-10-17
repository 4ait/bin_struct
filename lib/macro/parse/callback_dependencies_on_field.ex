defmodule BinStruct.Macro.Parse.CallbackDependenciesOnField do

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.Callback
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackItemArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackNewArgument
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Structs.InterfaceImplementation
  alias BinStruct.Macro.Parse.CallbacksOnField


  def field_dependencies_of_interface_implementation(%InterfaceImplementation{} = interface_implementation, registered_callbacks_map) do

    %InterfaceImplementation{ callback: callback } = interface_implementation

    field_dependencies_of_callbacks([callback], registered_callbacks_map)

  end

  def field_dependencies_of_callbacks_on_fields(%Field{} = field, registered_callbacks_map) do

    callbacks_on_field = CallbacksOnField.callbacks(field)

    field_dependencies_of_callbacks(callbacks_on_field, registered_callbacks_map)

  end

  def field_dependencies_of_callbacks(callbacks, registered_callbacks_map) do

    Enum.map(
      callbacks,
      fn %Callback{} = callback ->

        registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, callback)

        %RegisteredCallback{ arguments: arguments } = registered_callback

        Enum.map(
          arguments,
          fn argument ->

            case argument do
              %RegisteredCallbackFieldArgument{} = field_argument -> field_argument
              %RegisteredCallbackItemArgument{} = item_argument -> item_argument
              %RegisteredCallbackOptionArgument{} = _option_argument -> nil
              %RegisteredCallbackNewArgument{} = _new_argument -> nil
            end

          end
        )
      end
    )
    |> List.flatten()
    |> Enum.reject(&is_nil/1)
    |> Enum.dedup_by(
         fn argument ->

           case argument do

             %RegisteredCallbackFieldArgument{field: field} ->
               %Field{ name: name } = field
               name

             %RegisteredCallbackItemArgument{item_of_field: item_of_field} ->
               %Field{ name: name } = item_of_field
               name
           end

         end
       )

  end



end