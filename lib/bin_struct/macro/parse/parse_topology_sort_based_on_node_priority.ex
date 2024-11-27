defmodule BinStruct.Macro.Parse.ParseTopologySortBasedOnNodePriority do

  @moduledoc false

  alias BinStruct.Macro.Parse.ParseTopologyNodes.ParseNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.TypeConversionNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.VirtualFieldProducingNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.InterfaceImplementationNode

  alias BinStruct.Macro.TopologyAdditionalSortAccordingToPriority

  def sort_topology_based_on_node_priority(topology, edges) do
    TopologyAdditionalSortAccordingToPriority.sort_topology_based_on_node_priority(topology, edges, &priority/1)
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