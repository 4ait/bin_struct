defmodule BinStruct.Macro.DependenciesTopology do

  @moduledoc false

  def find_dependencies_topology(nodes_with_dependencies) do

   flat_tree = normalize_flatten(nodes_with_dependencies)

   graph =
    Graph.new()
    |> Graph.add_edges(flat_tree)

    case Graph.topsort(graph) do
      false -> { :error, :topology_not_exists }
      topology -> { :ok, topology }
    end


  end

  defp normalize_flatten(nodes_with_dependencies) do

      Enum.map(
        nodes_with_dependencies,
        fn { node, depend_on } ->

          Enum.map(
            depend_on,
            fn dependency ->
              { dependency, node }
            end
          )

        end
      )
      |> List.flatten()
      |> Enum.dedup()

  end

end