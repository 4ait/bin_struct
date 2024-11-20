defmodule BinStruct.Macro.Dependencies.CallbacksDependencies do

  @moduledoc false

  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.DependencyOnOption

  def dependencies(registered_callbacks) do

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

  end

end