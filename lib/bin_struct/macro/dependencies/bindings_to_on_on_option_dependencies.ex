defmodule BinStruct.Macro.Dependencies.BindingsToOnOptionDependencies do


  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.RegisteredOption

  def bindings(dependencies, context) do

    Enum.map(
      dependencies,
      fn dependency ->

        case dependency do

          %DependencyOnOption{} = on_option_dependency ->

            %DependencyOnOption{
              option: registered_option
            } = on_option_dependency

            %RegisteredOption{
              name: name,
              interface: interface
            } = registered_option

            { name, Bind.bind_option(interface, name, context) }

          %DependencyOnField{} -> nil

        end

      end
    )
    |> Enum.reject(&is_nil/1)

  end

end
