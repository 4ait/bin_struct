defmodule BinStruct.Macro.Dependencies.IsFieldDependentOn do

  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField


  def is_field_dependent_on(dependencies, field) do

    %Field{ name: name } = field

    Enum.any?(
      dependencies,
      fn dependency ->
        case dependency do

          %DependencyOnOption{} -> false

          %DependencyOnField{ field: field_from_dependency } ->

            case field_from_dependency do
              %Field{name: ^name} -> true
              %VirtualField{} -> false
            end

        end

      end
     )
  end

end
