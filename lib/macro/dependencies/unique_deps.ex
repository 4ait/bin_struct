defmodule BinStruct.Macro.Dependencies.UniqueDeps do

  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.RegisteredOption
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField

  def unique_dependencies(dependencies) do

    Enum.uniq_by(
      dependencies,
      fn dependency ->

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
    )

  end

end