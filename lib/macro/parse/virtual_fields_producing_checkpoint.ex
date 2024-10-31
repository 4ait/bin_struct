defmodule BinStruct.Macro.Parse.VirtualFieldsProducingCheckpoint do


  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Dependencies.CallbacksDependencies
  alias BinStruct.Macro.Dependencies.DeconstructionOfOnOptionDependencies
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies
  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Bind

  def virtual_fields_producing_checkpoint_function(
        function_name,
        input_dependencies,
        output_dependencies,
        registered_callbacks_map
      ) do

    dependencies_bindings = BindingsToOnFieldDependencies.bindings(input_dependencies, __MODULE__)

    virtual_fields_to_produce_dependencies =
      filter_dependencies_to_virtual_fields(output_dependencies)
      |> unique_dependencies_no_matter_type_conversion()

    { :ok, topology } = topology(virtual_fields_to_produce_dependencies, registered_callbacks_map)

    ordered =
      Enum.sort_by(
        virtual_fields_to_produce_dependencies,
        fn %DependencyOnField{ field: field } ->

          field_name =
            case field do
              %Field{ name: field_name } -> field_name
              %VirtualField{ name: field_name } -> field_name
            end

          Enum.find_index(
            topology,
            fn field_name_in_topology -> field_name_in_topology == field_name end
          )

        end
      )


    read_by_calls =

      Enum.map(
        ordered,

        fn %DependencyOnField{ field: field } ->

          %VirtualField{ name: field_name, opts: opts } = field

          registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, opts[:read_by])
          registered_callback_function_call = RegisteredCallbackFunctionCall.registered_callback_function_call(registered_callback, __MODULE__)

          managed_value_bind = Bind.bind_managed_value(field_name, __MODULE__)

          quote do

            unquote(managed_value_bind) = unquote(registered_callback_function_call)

          end

        end
      )

    returns =
      Enum.map(
        output_dependencies,
        fn  %DependencyOnField{} = dependency ->

          %DependencyOnField{
            field: %VirtualField{ name: name }
          } = dependency

          Bind.bind_managed_value(name, __MODULE__)


        end
      )

    quote do

      defp unquote(function_name)(unquote_splicing(dependencies_bindings), options) do

        unquote(
          DeconstructionOfOnOptionDependencies.option_dependencies_deconstruction(input_dependencies, __MODULE__)
        )

        unquote_splicing(read_by_calls)

        { unquote_splicing(returns) }

      end

    end


  end


  defp topology(virtual_fields_to_produce_dependencies, registered_callbacks_map) do


    flat_dependency_tree =
      Enum.map(
        virtual_fields_to_produce_dependencies,
        fn %DependencyOnField{} = dependency_on_field ->

          %DependencyOnField{
            field: virtual_field
          } = dependency_on_field

          %VirtualField{ name: name, opts: opts } = virtual_field

          sub_dependencies =
            case opts[:read_by] do

              read_by when not is_nil(read_by) ->

                registered_read_by_callback =
                  RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, read_by)

                CallbacksDependencies.dependencies([registered_read_by_callback])
                |> filter_dependencies_to_virtual_fields()
                |> unique_dependencies_no_matter_type_conversion()


              nil -> []

            end

          Enum.map(
            sub_dependencies,
            fn sub_dependency ->

              %DependencyOnField{
                field: %VirtualField { name: sub_dependency_name }
              } = sub_dependency

              { name, sub_dependency_name }

            end
          )

        end
      )
      |> List.flatten()
      |> Enum.dedup()


    graph =
      Graph.new()
      |> Graph.add_edges(flat_dependency_tree)

    case Graph.topsort(graph) do
      false -> { :error, :topology_not_exists }
      topology -> { :ok, Enum.reverse(topology) }
    end

  end

  defp filter_dependencies_to_virtual_fields(input_dependencies) do

    Enum.filter(
      input_dependencies,
      fn input_dependency ->

        case input_dependency do
          %DependencyOnField{} = dependency_on_field ->

            %DependencyOnField{
              field: field
            } = dependency_on_field

            case field do
              %Field{} -> false
              %VirtualField{} -> true
            end

          %DependencyOnOption{} -> false

        end

      end
    )

  end


  defp unique_dependencies_no_matter_type_conversion(virtual_fields_to_produce_dependencies) do

    Enum.uniq_by(
      virtual_fields_to_produce_dependencies,
      fn dependency_on_field ->

        %DependencyOnField{
          field: field
        } = dependency_on_field

        %VirtualField{ name: name } = field

        name

      end
    )

  end


end
