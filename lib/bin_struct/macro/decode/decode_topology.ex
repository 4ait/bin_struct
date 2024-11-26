defmodule BinStruct.Macro.Decode.DecodeTopology do

  @moduledoc false

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField

  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionUnspecified
  alias BinStruct.TypeConversion.TypeConversionManaged

  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument

  alias BinStruct.Macro.Decode.DecodeTopologyNodes.UnmanagedFieldValueNode
  alias BinStruct.Macro.Decode.DecodeTopologyNodes.TypeConversionNode
  alias BinStruct.Macro.Decode.DecodeTopologyNodes.VirtualFieldProducingNode

  def topology_all(fields, registered_callbacks_map) do
    topology(fields, registered_callbacks_map, :all)
  end

  def topology_only(fields, registered_callbacks_map, field_names_to_decode_only) do
    topology(fields, registered_callbacks_map, field_names_to_decode_only)
  end

  defp topology(
        fields,
        registered_callbacks_map,
        field_names_to_decode_or_all_atom
      ) do

    fields_to_decode =
      case field_names_to_decode_or_all_atom do

        :all -> fields

        field_names_to_decode ->

          Enum.filter(
            fields,
            fn field_or_virtual_field ->

              name =
                case field_or_virtual_field do
                  %Field{ name: name } -> name
                  %VirtualField{ name: name } -> name
                end

              Enum.member?(field_names_to_decode, name)

            end
          )

      end

    fields_to_decode = only_field_and_virtual_fields_with_read_by(fields_to_decode)

    connections_to_decode_nodes =
      Enum.map(
        fields_to_decode,
        fn field_or_virtual_field ->

          case field_or_virtual_field do
            %Field{} = field ->

              field_unmanaged_value_node = create_field_unmanaged_value_node(field)

              type_conversion_node = create_type_conversion_node(field, TypeConversionManaged)

              { field_unmanaged_value_node, type_conversion_node }

            %VirtualField{} = virtual_field ->
              connections_to_produce_virtual_field(virtual_field, registered_callbacks_map)
          end

        end
      ) |> List.flatten()

    edges = connections_to_decode_nodes

    graph =
      Graph.new()
      |> Graph.add_edges(edges)

    topology =
      case Graph.topsort(graph) do
        false -> raise "Topology not exists, there is arguments requesting field which is not yet available at this point"
        topology -> topology
      end

    #BinStruct.Macro.Parse.ParseTopologyDebug.print_topology(topology, "BEFORE SORT")

    BinStruct.Macro.Parse.DecodeTopologySortBasedOnNodePriority.sort_topology_based_on_node_priority(topology, edges)

    #|> BinStruct.Macro.Parse.ParseTopologyDebug.print_topology("AFTER SORT")

  end

  defp create_field_unmanaged_value_node(field), do: %UnmanagedFieldValueNode{ field: field }

  defp create_type_conversion_node(depend_on_field, type_conversion) do

    %TypeConversionNode{
      subject: depend_on_field,
      type_conversion: type_conversion
    }

  end

  defp create_virtual_field_producing_node(virtual_field) do

    %VirtualFieldProducingNode{
      virtual_field: virtual_field
    }

  end

  defp only_field_and_virtual_fields_with_read_by(fields) do

    Enum.filter(
      fields,
      fn field_or_virtual_field ->

        case field_or_virtual_field do
          %Field{} -> true
          %VirtualField{ opts: opts } ->

            case opts[:read_by] do

              read_by when not is_nil(read_by) -> true

              nil -> false

            end


        end

      end
    )

  end


  defp connections_to_produce_virtual_field(%VirtualField{} = virtual_field, registered_callbacks_map) do

    %VirtualField{ opts: opts } = virtual_field

    created_by_read_by_callback = opts[:read_by]

    case created_by_read_by_callback do

      read_by_callback when not is_nil(read_by_callback) ->

        registered_callback_read_by = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, read_by_callback)

        %RegisteredCallback{
          arguments: created_by_arguments
        } = registered_callback_read_by

        virtual_field_producing_node = create_virtual_field_producing_node(virtual_field)

        Enum.map(
          created_by_arguments,
          fn created_by_argument ->

            %RegisteredCallbackFieldArgument{ field: depend_on_field, type_conversion: depend_on_type_conversion } = created_by_argument

            case depend_on_field do

              %Field{} = depend_on_field ->

                field_unmanaged_value_node = create_field_unmanaged_value_node(depend_on_field)

                case depend_on_type_conversion do

                  TypeConversionUnmanaged -> { field_unmanaged_value_node, virtual_field_producing_node }

                  TypeConversionUnspecified ->

                    type_conversion_node = create_type_conversion_node(depend_on_field, TypeConversionManaged)

                    [
                      { field_unmanaged_value_node, type_conversion_node },
                      { type_conversion_node, virtual_field_producing_node }
                    ]

                  type_conversion ->

                    type_conversion_node = create_type_conversion_node(depend_on_field, type_conversion)

                    [
                      { field_unmanaged_value_node, type_conversion_node },
                      { type_conversion_node, virtual_field_producing_node }
                    ]

                end


              %VirtualField{} = depend_on_virtual_field ->

                virtual_field_current_field_depend_on_node = create_virtual_field_producing_node(depend_on_virtual_field)

                connections =
                  case depend_on_type_conversion do

                    TypeConversionManaged -> { virtual_field_current_field_depend_on_node, virtual_field_producing_node }
                    TypeConversionUnspecified -> { virtual_field_current_field_depend_on_node, virtual_field_producing_node }

                    type_conversion ->

                      type_conversion_node =
                        create_type_conversion_node(depend_on_virtual_field, type_conversion)

                      [
                        { virtual_field_current_field_depend_on_node, type_conversion_node },
                        { type_conversion_node, virtual_field_producing_node }
                      ]

                  end

                additional_connections_to_create_depend_on_virtual_field_itself =
                  connections_to_produce_virtual_field(depend_on_virtual_field, registered_callbacks_map)

                List.flatten([
                  connections,
                  additional_connections_to_create_depend_on_virtual_field_itself
                ])

            end

          end
        )
        |> Enum.reject(&is_nil/1)
        |> List.flatten()


      nil ->

        %VirtualField{ name: name } = virtual_field
        raise "Depend on  virtual field without read_by callback defined as registered callback argument not possible, field name: #{inspect(name)}"

    end


  end



end