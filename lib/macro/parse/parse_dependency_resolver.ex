defmodule BinStruct.Macro.Parse.ParseDependencyResolver do

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.TypeConverterToBinary
  alias BinStruct.Macro.TypeConverterToManaged

  alias BinStruct.TypeConversion.TypeConversionBinary
  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionUnspecified

  def parse_dependency_resolvers(dependencies_to_resolve, context) do

    Enum.map(
      dependencies_to_resolve,
      fn dependency_to_resolve ->

        case dependency_to_resolve do

          %DependencyOnField{} = dependency_on_field ->

            %DependencyOnField{
              field: field,
              type_conversion: type_conversion
            } = dependency_on_field

            { name, type } =
              case field do
                %Field{ name: name, type: type } -> { name, type }
                %VirtualField{ name: name, type: type } -> { name, type }
              end

            managed_value_bind = Bind.bind_managed_value(name, context)
            unmanaged_value_bind = Bind.bind_unmanaged_value(name, context)

            case type_conversion do

              TypeConversionUnspecified ->

                quote do

                  unquote(managed_value_bind) = unquote(
                    TypeConverterToManaged.convert_unmanaged_value_to_managed(
                      type,
                      unmanaged_value_bind
                    )
                  )

                end

              TypeConversionManaged ->

                quote do

                  unquote(managed_value_bind) = unquote(
                    TypeConverterToManaged.convert_unmanaged_value_to_managed(
                      type,
                      unmanaged_value_bind
                    )
                  )

                end

              TypeConversionUnmanaged -> nil

              TypeConversionBinary ->

                quote do

                  unquote(managed_value_bind) = unquote(
                    TypeConverterToBinary.convert_unmanaged_value_to_binary(
                      type,
                      unmanaged_value_bind
                    )
                  )

                end

            end

          %DependencyOnOption{} -> nil

        end

      end

    ) |> Enum.reject(&is_nil/1)

  end


end