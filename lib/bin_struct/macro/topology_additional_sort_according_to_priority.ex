defmodule BinStruct.Macro.TopologyAdditionalSortAccordingToPriority do

  def sort_topology_based_on_node_priority(topology, edges, priority_fun) do
    connection_rules = MapSet.new(edges)
    do_steps_to_until_unchanged(topology, connection_rules, priority_fun)
  end

  defp can_swap?(node_a, node_b, connection_rules) do
    # Check that no rule requires node_b to come after node_a
    !MapSet.member?(connection_rules, { node_a, node_b })
  end

  defp should_try_to_swap_according_to_priority?(node_a, node_b, priority_fun) do
    priority_fun.(node_a) > priority_fun.(node_b)
  end

  defp do_steps_to_until_unchanged(topology, connection_rules, priority_fun) do

    case try_perform_single_swap([], topology, connection_rules, priority_fun) do
      { [], true, single_step_changed_topology } ->
        do_steps_to_until_unchanged(single_step_changed_topology, connection_rules, priority_fun)
      { [], false, non_changed_topology } -> non_changed_topology
    end

  end

  defp try_perform_single_swap(left, [ node_a, node_b | rest ], connection_rules, priority_fun) do

    should_swap = should_try_to_swap_according_to_priority?(node_a, node_b, priority_fun) && can_swap?(node_a, node_b, connection_rules)

    if should_swap do
      new_topology = left ++ [ node_b, node_a ] ++ rest

      { [], true, new_topology }

    else

      new_left = left ++ [ node_a ]
      part_of_topology = [ node_b ] ++ rest

      try_perform_single_swap(new_left, part_of_topology, connection_rules, priority_fun)

    end

  end

  defp try_perform_single_swap(left, less_then_2_items, _connection_rules, _priority_fun) do

    { [], false, left ++ less_then_2_items  }

  end


end
