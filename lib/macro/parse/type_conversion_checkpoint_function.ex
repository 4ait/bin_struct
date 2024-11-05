defmodule BinStruct.Macro.Parse.TypeConversionCheckpointFunction do

  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.IsOptionalField

  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionBinary
  alias BinStruct.TypeConversion.TypeConversionUnspecified

  alias BinStruct.Macro.TypeConverterToManaged
  alias BinStruct.Macro.TypeConverterToBinary

  alias BinStruct.Macro.OptionalNilCheckExpression

  alias BinStruct.Macro.Structs.TypeConversionCheckpoint
  alias BinStruct.Macro.Parse.ParseTopologyNodes.TypeConversionNode

  def receiving_arguments_bindings(%TypeConversionCheckpoint{} = checkpoint, _registered_callbacks_map, context) do

    %TypeConversionCheckpoint{ type_conversion_nodes: type_conversion_nodes } = checkpoint

    Enum.map(
      type_conversion_nodes,
      fn type_conversion_node ->

        %TypeConversionNode{
          subject: subject
        } = type_conversion_node

        name =
          case subject do
            %Field{ name: name } -> name
            %VirtualField{ name: name } -> name
          end

        Bind.bind_unmanaged_value(name, context)

      end
    )

  end

  def output_bindings(%TypeConversionCheckpoint{} = checkpoint, _registered_callbacks_map, context) do

    %TypeConversionCheckpoint{ type_conversion_nodes: type_conversion_nodes } = checkpoint

    Enum.map(
      type_conversion_nodes,
      fn type_conversion_node ->

        %TypeConversionNode{
          subject: subject,
          type_conversion: type_conversion
        } = type_conversion_node

        name =
          case subject do
            %Field{ name: name } -> name
            %VirtualField{ name: name } -> name
          end

        case type_conversion do
          TypeConversionUnspecified -> Bind.bind_managed_value(name, context)
          TypeConversionManaged -> Bind.bind_managed_value(name, context)
          TypeConversionUnmanaged -> Bind.bind_unmanaged_value(name, context)
          TypeConversionBinary-> Bind.bind_binary_value(name, context)
        end

      end
    )

  end


  def type_conversion_checkpoint_function(
        %TypeConversionCheckpoint{} = checkpoint,
        function_name,
        registered_callbacks_map,
        _env
      ) do

    receiving_arguments_bindings = receiving_arguments_bindings(checkpoint, registered_callbacks_map, __MODULE__)
    output_bindings = output_bindings(checkpoint, registered_callbacks_map, __MODULE__)

    %TypeConversionCheckpoint{ type_conversion_nodes: type_conversion_nodes } = checkpoint

    conversions =
      Enum.map(
        type_conversion_nodes,

        fn type_conversion_node ->

          %TypeConversionNode{
            subject: subject,
            type_conversion: type_conversion
          } = type_conversion_node

          { name, type, is_optional } =

            case subject do
              %Field{ name: name, type: type } = field ->

                { name, type, IsOptionalField.is_optional_field(field) }

              %VirtualField{ name: name, type: type } -> { name, type, true }

            end

          unmanaged_value_access = Bind.bind_unmanaged_value(name, __MODULE__)

          case type_conversion do

            TypeConversionUnspecified ->

              TypeConverterToManaged.convert_unmanaged_value_to_managed(type, unmanaged_value_access)
              |> OptionalNilCheckExpression.maybe_wrap_optional(unmanaged_value_access, is_optional)

            TypeConversionManaged ->

              TypeConverterToManaged.convert_unmanaged_value_to_managed(type, unmanaged_value_access)
              |> OptionalNilCheckExpression.maybe_wrap_optional(unmanaged_value_access, is_optional)

            TypeConversionUnmanaged -> unmanaged_value_access

            TypeConversionBinary ->

              TypeConverterToBinary.convert_unmanaged_value_to_binary(type, unmanaged_value_access)
              |> OptionalNilCheckExpression.maybe_wrap_optional(unmanaged_value_access, is_optional)

          end

        end
      )

    quote do

      defp unquote(function_name)(unquote_splicing(receiving_arguments_bindings)) do

         unquote_splicing(conversions)

        { unquote_splicing(output_bindings) }

      end

    end

  end


end
