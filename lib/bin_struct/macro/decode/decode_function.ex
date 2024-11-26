defmodule BinStruct.Macro.Decode.DecodeFunction do

  @moduledoc false

  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.IsOptionalField
  alias BinStruct.Macro.TypeConverterToManaged

  alias BinStruct.Macro.Decode.DecodeTopologyNodes.UnmanagedFieldValueNode
  alias BinStruct.Macro.Decode.DecodeTopologyNodes.TypeConversionNode
  alias BinStruct.Macro.Decode.DecodeTopologyNodes.VirtualFieldProducingNode

  alias BinStruct.Macro.Decode.Steps.DecodeStepOpenUnmanagedValues
  alias BinStruct.Macro.Decode.Steps.DecodeStepApplyTypeConversions
  alias BinStruct.Macro.Decode.Steps.DecodeStepProduceVirtualFields

  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionBinary
  alias BinStruct.Macro.OptionalNilCheckExpression

  alias BinStruct.Macro.TypeConverterToManaged
  alias BinStruct.Macro.TypeConverterToBinary
  alias BinStruct.Macro.RegisteredCallbackFunctionCall

  alias BinStruct.Macro.Structs.RegisteredCallbacksMap

  alias BinStruct.Macro.Decode.DecodeTopology

  def decode_function(fields, registered_callbacks_map, _env) do

    topology = DecodeTopology.topology_all(fields, registered_callbacks_map)

    decode_steps = create_decode_steps_from_topology(topology)

    { function_head_struct_deconstruction, decode_steps } = function_head_deconstruction_optimization(decode_steps)

    steps_code = steps_code(decode_steps, registered_callbacks_map)

    result_decode_map_pairs = result_decode_map_pairs(fields)

    quote do

      def decode(
            %__MODULE__{
              unquote_splicing(function_head_struct_deconstruction)
            } = bin_struct
          ) do

        unquote_splicing(steps_code)

        %{
          unquote_splicing(result_decode_map_pairs)
        }

      end

    end

  end

  def decode_only_labeled_function(fields, registered_callbacks_map, function_label, only_fields_names, _env) do


    topology = DecodeTopology.topology_only(fields, registered_callbacks_map, only_fields_names)

    IO.inspect(topology)

    decode_steps = create_decode_steps_from_topology(topology)

    { function_head_struct_deconstruction, decode_steps } = function_head_deconstruction_optimization(decode_steps)

    steps_code = steps_code(decode_steps, registered_callbacks_map)

    decode_only_fields =
      Enum.filter(
        fields,
        fn field ->

          name =
            case field do
              %Field{ name: name } -> name
              %VirtualField{ name: name } -> name
            end

          name in only_fields_names

        end
      )

    result_decode_map_pairs = result_decode_map_pairs(decode_only_fields)

    quote do

      def unquote(function_label)(
            %__MODULE__{
              unquote_splicing(function_head_struct_deconstruction)
            } = bin_struct
          ) do

        unquote_splicing(steps_code)

        %{
          unquote_splicing(result_decode_map_pairs)
        }

      end

    end


  end

  def decode_only_unlabeled_fallback_to_decode_all_with_warning_function() do

    quote do

      require Logger

      def decode_only(
            %__MODULE__{} = bin_struct,
            only_field_names_not_matched
          ) do

        Logger.warning("decode_only not matched #{inspect(only_field_names_not_matched)}")

        Enum.filter(
          decode(bin_struct),
          fn { k, v } ->  k in only_field_names_not_matched end
        ) |> Enum.into(%{})

      end

    end

  end

  def decode_only_unlabeled_function(fields, registered_callbacks_map, only_fields_names, _env) do

    topology = DecodeTopology.topology_only(fields, registered_callbacks_map, only_fields_names)

    decode_steps = create_decode_steps_from_topology(topology)

    { function_head_struct_deconstruction, decode_steps } = function_head_deconstruction_optimization(decode_steps)

    steps_code = steps_code(decode_steps, registered_callbacks_map)

    decode_only_fields =
      Enum.filter(
        fields,
        fn field ->

          name =
            case field do
              %Field{ name: name } -> name
              %VirtualField{ name: name } -> name
            end

          name in only_fields_names

        end
      )

    result_decode_map_pairs = result_decode_map_pairs(decode_only_fields)

    quote do

      def decode_only(
            %__MODULE__{
              unquote_splicing(function_head_struct_deconstruction)
            } = bin_struct,
            unquote(only_fields_names)
          ) do

        unquote_splicing(steps_code)

        %{
          unquote_splicing(result_decode_map_pairs)
        }

      end

    end

  end

  #optimization in case first decode step is opening umnamanged values (will happen mostly, currently all the time)
  #first deconstruction will happen directly in function head
  defp function_head_deconstruction_optimization(decode_steps) do

    case decode_steps do

      [ %DecodeStepOpenUnmanagedValues{ fields: fields } | rest ] ->

        function_head_struct_deconstruction = struct_unmanaged_values_deconstruction_pairs(fields)
        { function_head_struct_deconstruction, rest }

      _ -> { [], decode_steps }

    end

  end

  defp steps_code(decode_steps, registered_callbacks_map) do

    Enum.map(
      decode_steps,
      fn decode_step ->

        case decode_step do

          %DecodeStepOpenUnmanagedValues{ fields: fields } ->
            code_for_decode_step_open_unmanaged_values(fields)

          %DecodeStepApplyTypeConversions{ type_conversion_nodes: type_conversion_nodes } ->
            code_for_decode_step_apply_type_conversions(type_conversion_nodes)

          %DecodeStepProduceVirtualFields{ virtual_fields: virtual_fields } ->
            code_for_decode_step_produce_virtual_fields(virtual_fields, registered_callbacks_map)

        end

      end
    )

  end

  defp result_decode_map_pairs(fields) do

    Enum.map(
      fields,
      fn field ->

        name =
          case field do
            %Field{ name: name } -> name
            %VirtualField{ name: name } -> name
          end

        { name, Bind.bind_managed_value(name, __MODULE__) }

      end)

  end

  defp struct_unmanaged_values_deconstruction_pairs(fields) do

    Enum.map(
      fields,
      fn field ->

        %Field{ name: name } = field

        { name, Bind.bind_unmanaged_value(name, __MODULE__) }

      end
    )

  end

  defp code_for_decode_step_open_unmanaged_values(fields) do

    struct_deconstruction_pairs = struct_unmanaged_values_deconstruction_pairs(fields)

    quote do
      %__MODULE__{
        unquote_splicing(struct_deconstruction_pairs)
      } = bin_struct
    end

  end

  defp code_for_decode_step_apply_type_conversions(type_conversion_nodes) do

    conversions =
      Enum.map(
        type_conversion_nodes,
        fn type_conversion_node ->

          %TypeConversionNode{ subject: type_conversion_subject, type_conversion: target_type_conversion } = type_conversion_node

          is_optional =
            case type_conversion_subject do
             %Field{} = field -> IsOptionalField.is_optional_field(field)
             %VirtualField{} = _virtual_field -> true
            end


          field_name =
            case type_conversion_subject do
              %Field{ name: name } -> name
              %VirtualField{ name: name }  -> name
            end

          field_type =
            case type_conversion_subject do
              %Field{ type: type } -> type
              %VirtualField{ type: type } -> type
            end

          unmanaged_value_bind = Bind.bind_unmanaged_value(field_name, __MODULE__)
          managed_value_bind = Bind.bind_managed_value(field_name, __MODULE__)
          binary_value_bind = Bind.bind_binary_value(field_name, __MODULE__)

          case target_type_conversion do

            TypeConversionManaged ->

              managed_value_expr =
                TypeConverterToManaged.convert_unmanaged_value_to_managed(field_type, unmanaged_value_bind)
                |> OptionalNilCheckExpression.maybe_wrap_optional(unmanaged_value_bind, is_optional)

              quote do
                unquote(managed_value_bind) = unquote(managed_value_expr)
              end

            TypeConversionUnmanaged -> unmanaged_value_bind

            TypeConversionBinary ->

              binary_value_expr =
                TypeConverterToBinary.convert_unmanaged_value_to_binary(field_type, unmanaged_value_bind)
                |> OptionalNilCheckExpression.maybe_wrap_optional(unmanaged_value_bind, is_optional)

              quote do
                unquote(binary_value_bind) = unquote(binary_value_expr)
              end

          end

        end
      )

    quote do
      unquote_splicing(conversions)
    end


  end

  defp code_for_decode_step_produce_virtual_fields(virtual_fields, registered_callbacks_map) do


    read_by_calls =
      Enum.map(
        virtual_fields,
        fn virtual_field ->
           %VirtualField{ name: name, opts: opts } = virtual_field


           managed_value_bind = Bind.bind_managed_value(name, __MODULE__)

           read_by_callback = opts[:read_by]

           registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, read_by_callback)

           registered_callback_function_call = RegisteredCallbackFunctionCall.registered_callback_function_call(registered_callback, __MODULE__)


           quote do
             unquote(managed_value_bind) = unquote(registered_callback_function_call)
           end

        end
      )


    quote do
      unquote_splicing(read_by_calls)
    end

  end


  defp create_decode_steps_from_topology(decode_topology) do
    create_decode_steps_from_topology_rec(decode_topology, nil, [])
  end

  defp create_decode_steps_from_topology_rec([], current_step, steps_acc) do

    steps_acc =
      case current_step do
        nil -> steps_acc
        current_step -> [ current_step | steps_acc ]
      end

    Enum.reverse(steps_acc)

  end

  defp create_decode_steps_from_topology_rec([ head_node | remain_nodes ], current_step, steps_acc) do


    case head_node do

      %UnmanagedFieldValueNode{} = unmanaged_field_value_node ->
        add_umanaged_field_value_node(unmanaged_field_value_node, remain_nodes, current_step, steps_acc)

      %TypeConversionNode{} = type_conversion_node ->
        add_type_conversion_node(type_conversion_node, remain_nodes, current_step, steps_acc)

      %VirtualFieldProducingNode{} = virtual_field_producing_node ->
        add_virtual_field_producing_node(virtual_field_producing_node, remain_nodes, current_step, steps_acc)

    end

  end


  defp add_umanaged_field_value_node(%UnmanagedFieldValueNode{} = unmanaged_field_value_node, remain_nodes, current_step, steps_acc) do

    %UnmanagedFieldValueNode{ field: field } = unmanaged_field_value_node

    case current_step do

      %DecodeStepOpenUnmanagedValues{ fields: fields } ->

        decode_step = %DecodeStepOpenUnmanagedValues{ fields: fields ++ [field] }

        create_decode_steps_from_topology_rec(
          remain_nodes,
          decode_step,
          steps_acc
        )

      _ ->

        next_decode_step = %DecodeStepOpenUnmanagedValues{ fields: [field] }

        case current_step do

          nil ->

            create_decode_steps_from_topology_rec(
              remain_nodes,
              next_decode_step,
              steps_acc
            )

          current_checkpoint ->

            create_decode_steps_from_topology_rec(
              remain_nodes,
              next_decode_step,
              [ current_checkpoint | steps_acc ]
            )

        end

    end

  end



  defp add_type_conversion_node(%TypeConversionNode{} = type_conversion_node, remain_nodes, current_step, steps_acc) do


    case current_step do

      %DecodeStepApplyTypeConversions{ type_conversion_nodes: type_conversion_nodes } ->

        decode_step = %DecodeStepApplyTypeConversions{ type_conversion_nodes: type_conversion_nodes ++ [ type_conversion_node ] }

        create_decode_steps_from_topology_rec(
          remain_nodes,
          decode_step,
          steps_acc
        )

      _ ->

        next_checkpoint = %DecodeStepApplyTypeConversions{ type_conversion_nodes: [ type_conversion_node ] }

        case current_step do

          nil ->

            create_decode_steps_from_topology_rec(
              remain_nodes,
              next_checkpoint,
              steps_acc
            )

          current_checkpoint ->

            create_decode_steps_from_topology_rec(
              remain_nodes,
              next_checkpoint,
              [ current_checkpoint | steps_acc ]
            )

        end

    end

  end


  defp add_virtual_field_producing_node(%VirtualFieldProducingNode{} = virtual_field_producing_node, remain_nodes, current_step, steps_acc) do


    %VirtualFieldProducingNode{ virtual_field: virtual_field } = virtual_field_producing_node

    case current_step do

      %DecodeStepProduceVirtualFields{ virtual_fields: virtual_fields } ->

        next_checkpoint = %DecodeStepProduceVirtualFields{ virtual_fields: virtual_fields ++ [ virtual_field ] }

        create_decode_steps_from_topology_rec(
          remain_nodes,
          next_checkpoint,
          steps_acc
        )

      _ ->

        next_checkpoint = %DecodeStepProduceVirtualFields{ virtual_fields: [ virtual_field ] }

        case current_step do

          nil ->

            create_decode_steps_from_topology_rec(
              remain_nodes,
              next_checkpoint,
              steps_acc
            )

          current_checkpoint ->

            create_decode_steps_from_topology_rec(
              remain_nodes,
              next_checkpoint,
              [ current_checkpoint | steps_acc ]
            )

        end

    end

  end

end

