defmodule BinStruct.Macro.Parse.TypeConverterCheckpointInputOutputByIndex do

  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.Structs.RegisteredOption

  def type_converter_checkpoint_input_output_by_index(consumed_dependencies_per_checkpoint) do

    consumed_dependencies_with_index =
      Enum.map(
        Enum.with_index(consumed_dependencies_per_checkpoint, 1),
        fn { dependencies, checkpoint_index } ->

          Enum.map(
            dependencies,
            fn dependency -> { checkpoint_index, dependency } end
          )

        end
      ) |> List.flatten()

    unique_by_output_dependencies_by_index =
      Enum.group_by(
        consumed_dependencies_with_index,
        fn { _checkpoint_index, consume_dependency } ->
          unique_by_output(consume_dependency)
        end
      )

    output_by_index =
      Enum.map(unique_by_output_dependencies_by_index, fn { _ , dependencies} ->
          { min_index, dependency_with_min_index } = Enum.min_by(dependencies, fn {index, _dependency} -> index end)
          { min_index, dependency_with_min_index }
        end)
      |> Enum.group_by(fn { index, _dep } -> index end)

    Enum.map(output_by_index, fn { index , dependencies_with_index } ->

      dependencies_without_index =
        Enum.map(
          dependencies_with_index,
          fn { _dep_index, dep } -> dep end
        )

      output = dependencies_without_index
      input = Enum.uniq_by(dependencies_without_index, &unique_by_input/1)

      { index, input, output }

    end)


  end

  defp unique_by_input(dependency) do

    case dependency do

      %DependencyOnOption{} = on_option_dependency ->

        %DependencyOnOption{ option: option } = on_option_dependency

        %RegisteredOption{ name: name, interface: interface } = option

        { :option, { name, interface }  }

      %DependencyOnField{} = on_field_dependency ->

        %DependencyOnField{ field: field } = on_field_dependency

        field_name =
          case field do
            %Field{ name: name } -> name
            %VirtualField{ name: name } -> name
          end

        { :field, field_name }

    end

  end

  defp unique_by_output(dependency) do

      case dependency do

        %DependencyOnOption{} = on_option_dependency ->

          %DependencyOnOption{ option: option } = on_option_dependency

          %RegisteredOption{ name: name, interface: interface } = option

          { :option, { name, interface }  }

        %DependencyOnField{} = on_field_dependency ->

          %DependencyOnField{ field: field, type_conversion: type_conversion } = on_field_dependency

          field_name =

            case field do
              %Field{ name: name } -> name
              %VirtualField{ name: name } -> name
            end

          { :field, { field_name, type_conversion }  }

      end

  end

end
