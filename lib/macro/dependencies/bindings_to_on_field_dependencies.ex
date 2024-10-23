defmodule BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies do


  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.DependencyOnField

  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionBinary
  alias BinStruct.TypeConversion.TypeConversionUnspecified

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField

  def bindings(dependencies, context) do

    Enum.map(
      dependencies,
      fn dependency ->

        case dependency do

          %DependencyOnOption{} -> nil

          %DependencyOnField{} = on_field_dependency ->

            %DependencyOnField{ field: field, type_conversion: type_conversion } = on_field_dependency

            name =
              case field do
                %Field{ name: name } -> name
                %VirtualField{ name: name } -> name
              end

            case type_conversion do

              TypeConversionUnmanaged ->
                Bind.bind_unmanaged_value(name, context)

              TypeConversionManaged ->
                Bind.bind_managed_value(name, context)

              TypeConversionBinary ->
                Bind.bind_binary_value(name, context)

              TypeConversionUnspecified ->
                Bind.bind_managed_value(name, context)

            end

        end

      end
    )
    |> Enum.reject(&is_nil/1)

  end

end
