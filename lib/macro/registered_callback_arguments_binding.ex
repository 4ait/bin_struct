defmodule BinStruct.Macro.RegisteredCallbackArgumentsBinding do

  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.RegisteredOption
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.TypeConverter
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.IsOptionalField
  alias BinStruct.Macro.Bind

  alias BinStruct.Macro.Structs.TypeConversionUnspecified
  alias BinStruct.Macro.Structs.TypeConversionManaged
  alias BinStruct.Macro.Structs.TypeConversionUnmanaged

  def registered_callback_arguments_bindings(
        %RegisteredCallback{ arguments: arguments },
        how_to_treat_unspecified,
        context
      ) do

    Enum.map(
      arguments,
      fn argument ->

        case argument do

          %RegisteredCallbackFieldArgument{ field: %Field{} } = argument ->
            arguments_bindings_for_field_argument(argument, how_to_treat_unspecified, context)

          %RegisteredCallbackFieldArgument{ field: %VirtualField{} } = argument ->
            arguments_bindings_for_virtual_field_argument(argument, how_to_treat_unspecified, context)

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

  defp arguments_bindings_for_field_argument(argument, how_to_treat_unspecified, context) do

    %RegisteredCallbackFieldArgument{ field: field, type_conversion: type_conversion } = argument

    %Field { name: name } = field

    case type_conversion do

      %TypeConversionUnmanaged{} -> Bind.bind_unmanaged_value(name, context)

      %TypeConversionManaged{} -> Bind.bind_managed_value(name, context)

      %TypeConversionUnspecified{} ->

        case how_to_treat_unspecified do
          :unspecified_as_managed -> Bind.bind_managed_value(name, context)
          :unspecified_as_unmanaged -> Bind.bind_unmanaged_value(name, context)
        end

    end

  end

  defp arguments_bindings_for_virtual_field_argument(argument, how_to_treat_unspecified, context) do

    %RegisteredCallbackFieldArgument{ field: virtual_field, type_conversion: type_conversion } = argument

    %VirtualField { name: name } = virtual_field

    case type_conversion do

      %TypeConversionUnmanaged{} -> Bind.bind_unmanaged_value(name, context)

      %TypeConversionManaged{} -> Bind.bind_managed_value(name, context)

      %TypeConversionUnspecified{} ->

        case how_to_treat_unspecified do
          :unspecified_as_managed -> Bind.bind_managed_value(name, context)
          :unspecified_as_unmanaged -> Bind.bind_unmanaged_value(name, context)
        end

    end

  end

  defp wrap_with_nil_check(bind, if_not_nil_quote) do

    quote do

      case unquote(bind) do
        nil -> nil
        unquote(bind) -> unquote(if_not_nil_quote)
      end

    end

  end



end