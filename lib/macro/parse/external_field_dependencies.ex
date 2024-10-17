defmodule BinStruct.Macro.Parse.ExternalFieldDependencies do

  alias BinStruct.Macro.Parse.CallbacksDependenciesAll
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackItemArgument
  alias BinStruct.Macro.Structs.Field

  def external_field_dependencies(fields, interface_implementations, registered_callbacks_map) do

    field_dependencies = CallbacksDependenciesAll.field_dependencies_all(fields, interface_implementations, registered_callbacks_map)

    external_field_dependencies =
      Enum.filter(
        field_dependencies,
        fn argument ->

          case argument do
            %RegisteredCallbackFieldArgument{ field: field } -> !Enum.member?(fields, field)
            %RegisteredCallbackItemArgument{ item_of_field: item_of_field } -> !Enum.member?(fields, item_of_field)
          end

        end
      )

    Enum.uniq_by(
      external_field_dependencies,
      fn %RegisteredCallbackFieldArgument { field: field } ->
        %Field{name: name} = field
        name
      end
    )

  end


end