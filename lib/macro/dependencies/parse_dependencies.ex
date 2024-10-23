defmodule BinStruct.Macro.Dependencies.ParseDependencies do

  alias BinStruct.Macro.Bind

  def parse_dependencies(fields, registered_callbacks_map) do

    self_excluded_dependencies =
      Enum.map(
        fields,
        fn field ->

          callbacks = CallbacksOnField.callbacks_used_while_parsing(field, registered_callbacks_map)

          dependencies = CallbacksDependencies.dependencies(callbacks)

          ExcludeDependenciesOnField.exclude_dependencies_on_field(dependencies, field)

        end
      )
      |> List.flatten()

    UniqueDeps.unique_dependencies(self_excluded_dependencies)

  end

end
