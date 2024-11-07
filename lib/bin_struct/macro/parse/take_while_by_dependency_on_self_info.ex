defmodule BinStruct.Macro.Parse.TakeWhileByDependencyOnSelfInfo do

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionBinary
  alias BinStruct.TypeConversion.TypeConversionUnspecified
  alias BinStruct.Macro.Dependencies.CallbacksDependencies


  def take_while_by_dependency_on_self_info(current_field_name, take_while_by_registered_callback) do

    take_while_by_dependencies = CallbacksDependencies.dependencies([take_while_by_registered_callback])

    dependency_on_self_items_for_type_conversions =
      Enum.reduce(
        take_while_by_dependencies,
        [],
        fn take_while_by_dependency, acc ->

          case take_while_by_dependency do
            %DependencyOnField{ field: field, type_conversion: type_conversion } ->

              case field do
                %Field{ name: ^current_field_name } -> [ type_conversion | acc ]
                _ -> acc
              end

            _ -> acc

          end

        end
      )

    has_dependency_on_managed =
      Enum.any?(
        dependency_on_self_items_for_type_conversions,
        fn type_conversion -> type_conversion == TypeConversionManaged end
      )

    has_dependency_on_unspecified =
      Enum.any?(
        dependency_on_self_items_for_type_conversions,
        fn type_conversion -> type_conversion == TypeConversionUnspecified end
      )


    has_dependency_on_unmanaged =
      Enum.any?(
        dependency_on_self_items_for_type_conversions,
        fn type_conversion -> type_conversion == TypeConversionUnmanaged end
      )

    has_dependency_on_binary =
      Enum.any?(
        dependency_on_self_items_for_type_conversions,
        fn type_conversion -> type_conversion == TypeConversionBinary end
      )

    %{
      has_dependency_on_managed: has_dependency_on_managed,
      has_dependency_on_unspecified: has_dependency_on_unspecified,
      has_dependency_on_unmanaged: has_dependency_on_unmanaged,
      has_dependency_on_binary: has_dependency_on_binary
    }

  end

end
