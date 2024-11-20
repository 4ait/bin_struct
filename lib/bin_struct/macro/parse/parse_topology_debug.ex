defmodule BinStruct.Macro.Parse.ParseTopologyDebug do

  @moduledoc false

  alias BinStruct.Macro.Parse.ParseTopologyNodes.ParseNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.TypeConversionNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.VirtualFieldProducingNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.InterfaceImplementationNode

  def print_topology(topology, label \\ "") do

    IO.puts("")
    IO.puts("START TOPOLOGY #{label}>>")
    IO.puts("")

    Enum.map(
      topology,
      fn node ->

        case node do
          %ParseNode{ field: field } -> "ParseNode #{field.name}"
          %TypeConversionNode{ subject: subject, type_conversion: type_conversion } ->


            to =
              case type_conversion do
                BinStruct.TypeConversion.TypeConversionUnmanaged -> "Unmanaged"
                BinStruct.TypeConversion.TypeConversionManaged -> "Managed"
                BinStruct.TypeConversion.TypeConversionBinary -> "Binary"
              end

            "TypeConversionNode #{subject.name} to: #{to}"

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
    IO.puts("<< END TOPOLOGY #{label}")
    IO.puts("")

    topology

  end



end