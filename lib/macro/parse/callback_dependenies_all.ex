defmodule BinStruct.Macro.Parse.CallbacksDependenciesAll do

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Parse.CallbackDependenciesOnOptions
  alias BinStruct.Macro.Parse.CallbackDependenciesOnField

  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.RegisteredOption
  alias BinStruct.Macro.Structs.InterfaceImplementation

  def option_dependencies_all(fields, interface_implementations, registered_callbacks_map) do

    dependencies_of_callbacks_on_fields =
      Enum.map(
        fields,
        fn %Field{} = field ->
          CallbackDependenciesOnOptions.option_dependencies_of_callbacks_on_fields(field, registered_callbacks_map)
        end
      )

    dependencies_on_callbacks_on_interface_implementations =
      Enum.map(
        interface_implementations,
        fn %InterfaceImplementation{} = interface_implementation ->
          CallbackDependenciesOnOptions.option_dependencies_of_interface_implementation(interface_implementation, registered_callbacks_map)
        end
      )

    dependencies_all =  dependencies_of_callbacks_on_fields ++ dependencies_on_callbacks_on_interface_implementations

    dependencies_all
    |> List.flatten()
    |> Enum.dedup_by(
      fn %RegisteredCallbackOptionArgument{registered_option: registered_option} ->
        %RegisteredOption{ name: name } = registered_option
        name
      end
     )


  end

  def field_dependencies_all(fields, interface_implementations, registered_callbacks_map) do

    dependencies_of_callbacks_on_fields =
      Enum.map(
        fields,
        fn %Field{} = field ->
          CallbackDependenciesOnField.field_dependencies_of_callbacks_on_fields(field, registered_callbacks_map)
        end
      )

    dependencies_on_callbacks_on_interface_implementations =
      Enum.map(
        interface_implementations,
        fn %InterfaceImplementation{} = interface_implementation ->
          CallbackDependenciesOnField.field_dependencies_of_interface_implementation(interface_implementation, registered_callbacks_map)
        end
      )

    dependencies_all =  dependencies_of_callbacks_on_fields ++ dependencies_on_callbacks_on_interface_implementations

    dependencies_all
    |> List.flatten()
    |> Enum.dedup_by(
         fn argument ->

           case argument do

             %RegisteredCallbackFieldArgument{field: field} ->
               %Field{ name: name } = field
               name

           end

         end
       )

  end



end