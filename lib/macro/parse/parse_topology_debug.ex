defmodule BinStruct.Macro.Parse.ParseTopologyDebug do

  alias BinStruct.Macro.Parse.ParseTopologyNodes.ParseNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.TypeConversionNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.VirtualFieldProducingNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.InterfaceImplementationNode

  def print_topology(topology) do

    IO.puts("")
    IO.puts("START TOPOLOGY >>")
    IO.puts("")

    Enum.map(
      topology,
      fn node ->

        case node do
          %ParseNode{ field: field } -> "ParseNode #{field.name}"
          %TypeConversionNode{ subject: subject } -> "TypeConversionNode #{subject.name}"
          %VirtualFieldProducingNode{ virtual_field: virtual_field } -> "VirtualFieldProducingNode #{virtual_field.name}"
          %InterfaceImplementationNode{ interface_implementation: interface_implementation} ->

            { _, _, [interface] } = interface_implementation.interface

            "InterfaceImplementationNode #{interface}"
        end

      end
    )
    |> Enum.join("\n")
    |> IO.puts()


    IO.puts("")
    IO.puts("<< END TOPOLOGY")
    IO.puts("")

  end



end