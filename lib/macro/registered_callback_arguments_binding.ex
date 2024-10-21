defmodule BinStruct.Macro.RegisteredCallbackArgumentsBinding do

  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.RegisteredOption
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackNewArgument
  alias BinStruct.Macro.TypeConverter
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.IsOptionalField
  alias BinStruct.Macro.Bind

  alias BinStruct.Macro.Structs.TypeConversionUnspecified
  alias BinStruct.Macro.Structs.TypeConversionManaged
  alias BinStruct.Macro.Structs.TypeConversionUnmanaged



  defp arguments_bindings_for_field_argument(argument, context) do

    %RegisteredCallbackFieldArgument{ field: field, type_conversion: type_conversion } = argument

    %Field { name: name, type: type } = field

    bind = { BinStruct.Macro.Bind.bind_value_name(name), [], context }

    case type_conversion do

      %TypeConversionUnmanaged{} -> bind

      %TypeConversionManaged{} ->

        if IsOptionalField.is_optional_field(field) do

          wrap_with_nil_check(
            bind,
            TypeConverter.convert_unmanaged_value_to_managed(type, bind)
          )

        else
          TypeConverter.convert_unmanaged_value_to_managed(type, bind)
        end

      %TypeConversionUnspecified{} ->

        if IsOptionalField.is_optional_field(field) do

          wrap_with_nil_check(
            bind,
            TypeConverter.convert_unmanaged_value_to_managed(type, bind)
          )

        else
          TypeConverter.convert_unmanaged_value_to_managed(type, bind)
        end

    end

  end

  defp arguments_bindings_for_virtual_field_argument(argument, context) do

    %RegisteredCallbackFieldArgument{ field: virtual_field, type_conversion: type_conversion } = argument

    %VirtualField { name: name, type: type } = virtual_field

    bind = { BinStruct.Macro.Bind.bind_value_name(name), [], context }

    case type_conversion do

      %TypeConversionUnmanaged{} -> bind

      %TypeConversionManaged{} ->

        wrap_with_nil_check(
          bind,
          TypeConverter.convert_unmanaged_value_to_managed(type, bind)
        )

      %TypeConversionUnspecified{} ->

        wrap_with_nil_check(
          bind,
          TypeConverter.convert_unmanaged_value_to_managed(type, bind)
        )

    end

  end

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

          } -> { Bind.bind_option_name(interface, name), [], context }


        end

      end
    )

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