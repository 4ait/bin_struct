defmodule BinStruct.Macro.Dependencies.ExcludeDependenciesOnField do

  @moduledoc false

  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField

  def exclude_dependencies_on_field(dependencies, field_to_exclude) do

    field_to_exclude_name =
      case field_to_exclude do
        %Field{ name: name } -> name
        %VirtualField{ name: name } -> name
      end

    Enum.reject(
      dependencies,
      fn dependency ->

        case dependency do

          %DependencyOnOption{} -> false

          %DependencyOnField{} = on_field_dependency ->

            %DependencyOnField{ field: field } = on_field_dependency

              case field do
                %Field{ name: ^field_to_exclude_name } -> true
                %VirtualField{ name: ^field_to_exclude_name } -> true
                _ -> false
              end

        end

      end
    )

  end

end