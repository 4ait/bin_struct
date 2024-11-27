defmodule BinStruct.Macro.Parse.DecodeTopologySortBasedOnNodePriority do

  @moduledoc false

  alias BinStruct.Macro.Decode.DecodeTopologyNodes.UnmanagedFieldValueNode
  alias BinStruct.Macro.Decode.DecodeTopologyNodes.TypeConversionNode
  alias BinStruct.Macro.Decode.DecodeTopologyNodes.VirtualFieldProducingNode

  alias BinStruct.Macro.TopologyAdditionalSortAccordingToPriority

  def sort_topology_based_on_node_priority(topology, edges) do
    TopologyAdditionalSortAccordingToPriority.sort_topology_based_on_node_priority(topology, edges, &priority/1)
  end

  defp priority(node) do

    case node do
      %UnmanagedFieldValueNode{} -> 1
      %TypeConversionNode{} -> 2
      %VirtualFieldProducingNode{} -> 3
    end

  end


end