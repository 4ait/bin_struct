defmodule BinStruct.Macro.ReceivingDependenciesArgumentsBindings do


  alias BinStruct.Macro.Dependencies.CallbacksDependencies
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.Bind
  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionBinary
  alias BinStruct.TypeConversion.TypeConversionUnspecified

  def receiving_dependencies_arguments_bindings(registered_callbacks, context) do

    checkpoint_depends_on = CallbacksDependencies.dependencies(registered_callbacks)

    checkpoint_receiving_arguments_binds =
      Enum.map(
        checkpoint_depends_on,
        fn dependency ->

          case dependency do

            %DependencyOnField{ field: field, type_conversion: type_conversion } ->

              name =
                case field do
                  %Field{ name: name } -> name
                  %VirtualField{ name: name } -> name
                end

              case type_conversion do
                TypeConversionManaged -> Bind.bind_managed_value(name, context)
                TypeConversionBinary -> Bind.bind_binary_value(name, context)
                TypeConversionUnmanaged -> Bind.bind_unmanaged_value(name, context)
                TypeConversionUnspecified -> Bind.bind_managed_value(name, context)
              end

            %DependencyOnOption{} -> nil

          end

        end
      ) |> Enum.reject(&is_nil/1)

  end


end