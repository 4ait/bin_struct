defmodule BinStruct.Macro.CallbacksDependencies do

  alias BinStruct.Macro.Parse.CallbacksDependenciesAll
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackNewArgument
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.RegisteredOption
  alias BinStruct.Macro.Structs.VirtualField

  def dependencies(registered_callbacks) do

   dependencies =
     Enum.map(
       registered_callbacks,
       fn registered_callback ->

         %RegisteredCallback{ arguments: arguments } = registered_callback

         Enum.map(
           arguments,
           fn argument ->

              case argument do
                %RegisteredCallbackFieldArgument{} = field_argument ->

                  %RegisteredCallbackFieldArgument{
                    field: field,
                    type_conversion: type_conversion
                  } = field_argument

                  %DependencyOnField{
                    field: field,
                    type_conversion: type_conversion
                  }

                %RegisteredCallbackOptionArgument{} = option_argument ->

                  %RegisteredCallbackOptionArgument{
                    registered_option: registered_option
                  } = option_argument

                  %DependencyOnOption{
                    option: registered_option
                  }

              end

           end
         )

       end
    ) |> List.flatten()


    keep_only_unique_dependencies(dependencies)

  end

  defp keep_only_unique_dependencies(dependencies) do


    Enum.uniq_by(
      dependencies,
      fn dependency ->

        case dependency do

          %DependencyOnOption{} = on_option_dependency ->

            %DependencyOnOption{ option: option } = on_option_dependency

            %RegisteredOption{ name: name, interface: interface } = option

            { :option, { name, interface }  }

          %DependencyOnField{} = on_field_dependency ->

            %DependencyOnField{ field: field, type_conversion: type_conversion } = on_field_dependency

            field_name =
              case field do
                %Field{ name: name } -> name
                %VirtualField{ name: name } -> name
              end

            { :field, { field_name, type_conversion }  }

        end

      end
    )

  end

end