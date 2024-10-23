defmodule BinStruct.Macro.RegisteredCallbackArgumentsBinding do

  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.RegisteredOption
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.Bind

  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionBinary
  alias BinStruct.TypeConversion.TypeConversionUnspecified

  def registered_callback_arguments_bindings(
        %RegisteredCallback{ arguments: arguments },
        context
      ) do

    Enum.map(
      arguments,
      fn argument ->

        case argument do

          %RegisteredCallbackFieldArgument{ field: %Field{} } = argument ->
            arguments_bindings_for_field_argument(argument, context)

          %RegisteredCallbackFieldArgument{ field: %VirtualField{} } = argument ->
            arguments_bindings_for_virtual_field_argument(argument, context)

          %RegisteredCallbackOptionArgument{
            registered_option: %RegisteredOption {
              interface: interface,
              name: name
            }

          } -> Bind.bind_option(interface, name, context)

        end

      end
    )

  end

  defp arguments_bindings_for_field_argument(argument, context) do

    %RegisteredCallbackFieldArgument{ field: field, type_conversion: type_conversion } = argument

    %Field { name: name } = field

    case type_conversion do

      TypeConversionUnmanaged -> Bind.bind_unmanaged_value(name, context)
      TypeConversionManaged -> Bind.bind_managed_value(name, context)
      TypeConversionBinary -> Bind.bind_binary_value(name, context)
      TypeConversionUnspecified -> Bind.bind_managed_value(name, context)

    end

  end

  defp arguments_bindings_for_virtual_field_argument(argument, context) do

    %RegisteredCallbackFieldArgument{ field: virtual_field, type_conversion: type_conversion } = argument

    %VirtualField { name: name } = virtual_field

    case type_conversion do

      TypeConversionUnmanaged -> Bind.bind_unmanaged_value(name, context)
      TypeConversionManaged -> Bind.bind_managed_value(name, context)
      TypeConversionBinary -> Bind.bind_binary_value(name, context)
      TypeConversionUnspecified -> Bind.bind_managed_value(name, context)

    end

  end

end