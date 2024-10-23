defmodule BinStruct.Macro.Dependencies.ExcludeDependenciesOnField do

  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.Field

  def exclude_dependencies_on_field(dependencies, field_to_exclude) do

    %Field{ name: field_to_exclude_name } = field_to_exclude

    Enum.reject(
      dependencies,
      fn dependency ->

        case dependency do

          %DependencyOnOption{} -> false

          %DependencyOnField{} = on_field_dependency ->

            %DependencyOnField{ field: field } = on_field_dependency

              case field do
                %Field{ name: ^field_to_exclude_name } -> true
                _ -> false
              end

        end

      end
    )

  end

end