defmodule BinStruct.Macro.Parse.ParseTopologySortBasedOnNodePriority do

  @moduledoc false

  alias BinStruct.Macro.Parse.ParseTopologyNodes.ParseNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.TypeConversionNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.VirtualFieldProducingNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.InterfaceImplementationNode

  def sort_topology_based_on_node_priority(topology, edges) do
    connection_rules = MapSet.new(edges)
    do_steps_to_until_unchanged(topology, connection_rules)
  end

  defp can_swap?(node_a, node_b, connection_rules) do
    # Check that no rule requires node_b to come after node_a
    !MapSet.member?(connection_rules, { node_a, node_b })
  end

  defp should_try_to_swap_according_to_priority?(node_a, node_b) do
    priority(node_a) > priority(node_b)
  end

  defp do_steps_to_until_unchanged(topology, connection_rules) do

    case try_perform_single_swap([], topology, connection_rules) do
      { [], true, single_step_changed_topology } ->
        do_steps_to_until_unchanged(single_step_changed_topology, connection_rules)
      { [], false, non_changed_topology } -> non_changed_topology
    end

  end

  defp try_perform_single_swap(left, [ node_a, node_b | rest ], connection_rules) do

    should_swap = should_try_to_swap_according_to_priority?(node_a, node_b) && can_swap?(node_a, node_b, connection_rules)

    if should_swap do
      new_topology = left ++ [ node_b, node_a ] ++ rest

      { [], true, new_topology }

    else

      new_left = left ++ [ node_a ]
      part_of_topology = [ node_b ] ++ rest

      try_perform_single_swap(new_left, part_of_topology, connection_rules)

    end

  end

  defp try_perform_single_swap(left, less_then_2_items, _connection_rules) do

    { [], false, left ++ less_then_2_items  }

  end


  defp priority(node) do
    case node do
      %ParseNode{} -> 1
      %TypeConversionNode{} -> 2
      %VirtualFieldProducingNode{} -> 3
      %InterfaceImplementationNode{} -> 4
    end
  end


end