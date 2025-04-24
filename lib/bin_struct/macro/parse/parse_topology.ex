defmodule BinStruct.Macro.Parse.ParseTopology do

  @moduledoc false

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.NonVirtualFields
  alias BinStruct.Macro.CallbacksOnField
  alias BinStruct.Macro.Dependencies.CallbacksDependencies
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.DependencyOnOption

  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionUnspecified
  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument

  alias BinStruct.Macro.Parse.ParseTopologyNodes.ParseNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.TypeConversionNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.VirtualFieldProducingNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.InterfaceImplementationNode

  alias BinStruct.Macro.Dependencies.ExcludeDependenciesOnField
  alias BinStruct.Macro.Structs.InterfaceImplementation
  alias BinStruct.Macro.Parse.ParseTopologySortBasedOnNodePriority



  def topology(
        fields,
        registered_callbacks_map,
        interface_implementations
      ) do


    non_virtual_fields = NonVirtualFields.skip_virtual_fields(fields)

    parse_vertices =
      Enum.map(
        non_virtual_fields,
        fn field ->
          create_parse_node(field)
        end
      )

    connections_to_parse_nodes =
      Enum.reduce(
        non_virtual_fields,
        { [], nil },
        fn field, { edges_acc, prev_parse_node } ->

          current_parse_node = create_parse_node(field)

          type_conversion_connections = create_type_conversion_connections_for_parse_node(current_parse_node, registered_callbacks_map)
          virtual_field_producing_connections = create_virtual_field_producing_connections_for_parse_node(current_parse_node, registered_callbacks_map)

          if prev_parse_node do

            connection_between_parse_nodes = { prev_parse_node, current_parse_node }

            {
              List.flatten([
                edges_acc,
                connection_between_parse_nodes,
                type_conversion_connections,
                virtual_field_producing_connections
              ]),
              current_parse_node
            }

          else
            {
              List.flatten([
                edges_acc,
                type_conversion_connections,
                virtual_field_producing_connections
              ]),
              current_parse_node
            }

          end

        end
      )
      |> then(fn { edges_acc, _prev_node } -> edges_acc end)

    connections_to_interface_implementations_node =
      Enum.map(
        interface_implementations,
        fn interface_implementation ->

          interface_implementation_node = create_interface_implementation_node(interface_implementation)

          %InterfaceImplementation{ force_call_before_parse_field_names: force_call_before_parse_field_names } = interface_implementation

          maybe_force_calling_order_connections  =
            case force_call_before_parse_field_names do
              nil -> []
              force_call_before_parse_field_names ->

                dependent_on_interface_impl_call_fields =
                  Enum.filter(
                    fields,
                    fn field -> field.name in force_call_before_parse_field_names end
                  )

                Enum.map(
                  dependent_on_interface_impl_call_fields,
                  fn field ->

                    parse_node = create_parse_node(field)

                    { interface_implementation_node, parse_node }

                  end
                )

            end

          type_conversion_connections = create_type_conversion_connections_for_interface_implementation_node(interface_implementation_node, registered_callbacks_map)
          virtual_field_producing_connections = create_virtual_field_producing_connections_for_interface_implementation_node(interface_implementation_node, registered_callbacks_map)

          List.flatten([
            type_conversion_connections,
            virtual_field_producing_connections,
            maybe_force_calling_order_connections
          ])

        end
      )
      |> List.flatten()

    edges = connections_to_parse_nodes ++ connections_to_interface_implementations_node

    graph =
      Graph.new()
      |> Graph.add_vertices(parse_vertices)
      |> Graph.add_edges(edges)

    topology =
      case Graph.topsort(graph) do
        false -> raise "Topology not exists, there is arguments requesting field which is not yet available at this point"
        topology -> topology
      end

    #BinStruct.Macro.Parse.ParseTopologyDebug.print_topology(topology, "BEFORE SORT")

    ParseTopologySortBasedOnNodePriority.sort_topology_based_on_node_priority(topology, edges)
    #|> BinStruct.Macro.Parse.ParseTopologyDebug.print_topology("AFTER SORT")

  end

  defp create_parse_node(field), do: %ParseNode{ field: field }

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


  defp create_type_conversion_connections_for_interface_implementation_node(%InterfaceImplementationNode{} = interface_implementation_node, registered_callbacks_map) do

    %InterfaceImplementationNode{ interface_implementation: interface_implementation } = interface_implementation_node

    %InterfaceImplementation{callback: callback} = interface_implementation

    registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, callback)

    dependencies = CallbacksDependencies.dependencies([registered_callback])

    Enum.map(
      dependencies,
      fn dependency ->
        type_conversion_connections_for_dependency(dependency, interface_implementation_node)
      end
    )
    |> Enum.reject(&is_nil/1)
    |> List.flatten()

  end

  defp create_type_conversion_connections_for_parse_node(%ParseNode{ field: field } = current_parse_node, registered_callbacks_map) do

    callbacks = CallbacksOnField.callbacks_used_while_parsing(field, registered_callbacks_map)

    dependencies =
      CallbacksDependencies.dependencies(callbacks)
      |> ExcludeDependenciesOnField.exclude_dependencies_on_field(field)

    Enum.map(
      dependencies,
      fn dependency ->
        type_conversion_connections_for_dependency(dependency, current_parse_node)
      end
    )
    |> Enum.reject(&is_nil/1)
    |> List.flatten()

  end


  defp create_virtual_field_producing_connections_for_parse_node(%ParseNode{ field: field } = current_parse_node, registered_callbacks_map) do

    callbacks = CallbacksOnField.callbacks_used_while_parsing(field, registered_callbacks_map)

    dependencies = CallbacksDependencies.dependencies(callbacks)

    Enum.map(
      dependencies,
      fn dependency ->
        virtual_field_producing_for_dependency(dependency, current_parse_node, registered_callbacks_map)
      end
    )
    |> Enum.reject(&is_nil/1)
    |> List.flatten()

  end



  defp create_virtual_field_producing_connections_for_interface_implementation_node(%InterfaceImplementationNode{} = interface_implementation_node, registered_callbacks_map) do

    %InterfaceImplementationNode{ interface_implementation: interface_implementation } = interface_implementation_node

    %InterfaceImplementation{callback: callback} = interface_implementation

    registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, callback)

    dependencies = CallbacksDependencies.dependencies([registered_callback])

    Enum.map(
      dependencies,
      fn dependency ->
        virtual_field_producing_for_dependency(dependency, interface_implementation_node, registered_callbacks_map)
      end
    )
    |> Enum.reject(&is_nil/1)
    |> List.flatten()

  end




  defp create_interface_implementation_node(interface_implementation) do
    %InterfaceImplementationNode{ interface_implementation: interface_implementation }
  end


  defp type_conversion_connections_for_dependency(dependency, node_type_conversion_required_before) do

    case dependency do

      %DependencyOnOption{} -> nil

      %DependencyOnField{} = on_field_dependency ->

        %DependencyOnField{ field: depend_on_field, type_conversion: type_conversion } = on_field_dependency

        case depend_on_field do

          %Field{} = depend_on_field ->

            parse_node = create_parse_node(depend_on_field)

            case type_conversion do

              TypeConversionUnmanaged -> { parse_node, node_type_conversion_required_before }

              TypeConversionUnspecified ->

                type_conversion_node = create_type_conversion_node(depend_on_field, TypeConversionManaged)

                [
                  { parse_node, type_conversion_node },
                  { type_conversion_node, node_type_conversion_required_before }
                ]

              type_conversion ->

                type_conversion_node = create_type_conversion_node(depend_on_field, type_conversion)

                [
                  { parse_node, type_conversion_node },
                  { type_conversion_node, node_type_conversion_required_before }
                ]

            end

          %VirtualField{} = depend_on_virtual_field ->

            depend_on_node_virtual_field_producing_node = create_virtual_field_producing_node(depend_on_virtual_field)

            case type_conversion do

              TypeConversionManaged -> { depend_on_node_virtual_field_producing_node, node_type_conversion_required_before }
              TypeConversionUnspecified -> { depend_on_node_virtual_field_producing_node, node_type_conversion_required_before }

              type_conversion ->

                type_conversion_node =
                  create_type_conversion_node(depend_on_virtual_field, type_conversion)

                [
                  { depend_on_node_virtual_field_producing_node, type_conversion_node },
                  { type_conversion_node, node_type_conversion_required_before }
                ]

            end


        end

    end

  end



  defp virtual_field_producing_for_dependency(dependency, node_virtual_field_producing_required_before, registered_callbacks_map) do

    case dependency do

      %DependencyOnOption{} -> nil

      %DependencyOnField{} = on_field_dependency ->

        %DependencyOnField{ field: depend_on_field } = on_field_dependency

        case depend_on_field do

          %Field{} -> nil

          %VirtualField{} = virtual_field ->


            create_virtual_field_producing_node = create_virtual_field_producing_node(virtual_field)

            [
              indirect_connections_to_produce_virtual_field(virtual_field, registered_callbacks_map),
              { create_virtual_field_producing_node, node_virtual_field_producing_required_before }
            ]

        end

    end

  end

  defp indirect_connections_to_produce_virtual_field(%VirtualField{} = virtual_field, registered_callbacks_map) do

    %VirtualField{ opts: opts } = virtual_field

    created_by_read_by_callback = opts[:read_by]

    case created_by_read_by_callback do
      nil ->
        %VirtualField{ name: name } = virtual_field
        raise "Use virtual field without read_by callback defined as registered callback argument not possible, field name: #{inspect(name)}"

      read_by_callback ->

        registered_callback_read_by = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, read_by_callback)

        %RegisteredCallback{
          arguments: created_by_arguments
        } = registered_callback_read_by

        virtual_field_producing_node = create_virtual_field_producing_node(virtual_field)

        Enum.map(
          created_by_arguments,
          fn created_by_argument ->

            case created_by_argument do

              %RegisteredCallbackFieldArgument{ field: depend_on_field, type_conversion: depend_on_type_conversion } ->

                case depend_on_field do

                  %Field{} = depend_on_field ->

                    parse_node_of_dependent_on_field = create_parse_node(depend_on_field)

                    case depend_on_type_conversion do

                      TypeConversionUnmanaged -> { parse_node_of_dependent_on_field, virtual_field_producing_node }

                      TypeConversionUnspecified ->

                        type_conversion_node = create_type_conversion_node(depend_on_field, TypeConversionManaged)

                        [
                          { parse_node_of_dependent_on_field, type_conversion_node },
                          { type_conversion_node, virtual_field_producing_node }
                        ]

                      type_conversion ->

                        type_conversion_node = create_type_conversion_node(depend_on_field, type_conversion)

                        [
                          { parse_node_of_dependent_on_field, type_conversion_node },
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
                      indirect_connections_to_produce_virtual_field(depend_on_virtual_field, registered_callbacks_map)


                    List.flatten([
                      connections,
                      additional_connections_to_create_depend_on_virtual_field_itself
                    ])

                end

              %RegisteredCallbackOptionArgument{} -> nil
            end

          end
        )
        |> Enum.reject(&is_nil/1)
        |> List.flatten()

    end


  end



end