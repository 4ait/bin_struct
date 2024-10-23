defmodule BinStruct.Macro.Dependencies.DeconstructionOfOnOptionDependencies do

  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.RegisteredOption
  alias BinStruct.Macro.Bind

  def option_dependencies_deconstruction(dependencies, context) do

    options_bind_access = { :options, [], context }

    option_dependencies =
      Enum.filter(
        dependencies,
        fn dependency ->

          case dependency do
            %DependencyOnOption{} -> true
            %DependencyOnField{} -> false
          end

        end
      )

    options_dependencies_by_interface =
      Enum.group_by(
        option_dependencies,
        fn %DependencyOnOption{} = on_option_dependency ->

          %DependencyOnOption{
            option: registered_option
          } = on_option_dependency

          %RegisteredOption{
            interface: interface
          } = registered_option

          interface

        end
      )

    interfaces_deconstructing_key_values =
      Enum.map(
        options_dependencies_by_interface,
        fn interface_with_options ->

          { interface, options_dependencies } = interface_with_options

          interface_values =
            Enum.map(
              options_dependencies,
              fn %DependencyOnOption{} = on_option_dependency ->

                %DependencyOnOption{
                  option: registered_option
                } = on_option_dependency

                %RegisteredOption{
                  name: name,
                  interface: interface
                } = registered_option

                { name, Bind.bind_option(interface, name, context) }

              end
            )

          interface_values_map =
            quote do
              %{ unquote_splicing(interface_values) }
            end

          { _key = interface, interface_values_map }

        end
      )

    quote do
      %{
        unquote_splicing(interfaces_deconstructing_key_values)
      } = unquote(options_bind_access)
    end

  end

end
