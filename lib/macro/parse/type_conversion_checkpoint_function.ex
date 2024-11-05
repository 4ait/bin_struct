defmodule BinStruct.Macro.Parse.TypeConversionCheckpointFunction do

  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.IsOptionalField

  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionBinary
  alias BinStruct.TypeConversion.TypeConversionUnspecified

  alias BinStruct.Macro.TypeConverterToManaged
  alias BinStruct.Macro.TypeConverterToBinary

  alias BinStruct.Macro.OptionalNilCheckExpression

  alias BinStruct.Macro.Structs.TypeConversionCheckpoint


  def receiving_arguments_bindings(%TypeConversionCheckpoint{} = checkpoint, registered_callbacks_map, context) do

    %ParseCheckpoint{ fields: fields } = checkpoint

    dependencies = ParseDependencies.parse_dependencies_excluded_self(fields, registered_callbacks_map)

    BindingsToOnFieldDependencies.bindings(dependencies, context)

  end

  def output_bindings(%TypeConversionCheckpoint{} = checkpoint, registered_callbacks_map, context) do

    %ParseCheckpoint{ fields: fields } = checkpoint

    Enum.map(
      fields,
      fn field ->

        %Field{ name: name } = field

        Bind.bind_unmanaged_value(name, context)

      end
    )

  end


  def type_conversion_checkpoint_function(
        %TypeConversionCheckpoint{} = checkpoint,
        function_name,
        _env
      ) do

    input_binds =
      Enum.map(
        input_dependencies,
        fn input_dependency ->

          case input_dependency do
            %DependencyOnField{} = dependency ->

              %DependencyOnField{
                field: field
              } = dependency

              name =
                case field do
                  %Field{ name: name } -> name
                  %VirtualField{ name: name } -> name
                end

              Bind.bind_unmanaged_value(name, __MODULE__)

            %DependencyOnOption{} -> nil

          end

        end
      ) |> Enum.reject(&is_nil/1)

    output_values =
      Enum.map(
        output_dependencies,

        fn output_dependency ->

          case output_dependency do

            %DependencyOnField{} = dependency ->

              %DependencyOnField{
                field: field,
                type_conversion: type_conversion
              } = dependency

              { name, type, is_optional } =
                case field do
                  %Field{ name: name, type: type } = field ->

                    { name, type, IsOptionalField.is_optional_field(field) }

                  %VirtualField{ name: name, type: type } -> { name, type, true }
                end

              unmanaged_value_access = Bind.bind_unmanaged_value(name, __MODULE__)

              case type_conversion do

                TypeConversionUnspecified ->

                  TypeConverterToManaged.convert_unmanaged_value_to_managed(type, unmanaged_value_access)
                  |> OptionalNilCheckExpression.maybe_wrap_optional(unmanaged_value_access, is_optional)

                TypeConversionManaged ->

                  TypeConverterToManaged.convert_unmanaged_value_to_managed(type, unmanaged_value_access)
                  |> OptionalNilCheckExpression.maybe_wrap_optional(unmanaged_value_access, is_optional)

                TypeConversionUnmanaged -> unmanaged_value_access

                TypeConversionBinary ->

                  TypeConverterToBinary.convert_unmanaged_value_to_binary(type, unmanaged_value_access)
                  |> OptionalNilCheckExpression.maybe_wrap_optional(unmanaged_value_access, is_optional)

              end

            %DependencyOnOption{} -> nil

          end

        end
      ) |> Enum.reject(&is_nil/1)

    quote do

      defp unquote(function_name)(unquote_splicing(input_binds)) do
        { unquote_splicing(output_values)}
      end

    end

  end

  defp old() do

    input_binds =
      Enum.map(
        input_dependencies,
        fn input_dependency ->

          case input_dependency do
            %DependencyOnField{} = dependency ->

              %DependencyOnField{
                field: field
              } = dependency

              name =
                case field do
                  %Field{ name: name } -> name
                  %VirtualField{ name: name } -> name
                end

              Bind.bind_unmanaged_value(name, __MODULE__)

            %DependencyOnOption{} -> nil

          end

        end
      ) |> Enum.reject(&is_nil/1)

    output_binds =
      Enum.map(
        output_dependencies,
        fn output_dependency ->

          case output_dependency do

            %DependencyOnField{} = dependency ->

              %DependencyOnField{
                field: field,
                type_conversion: type_conversion
              } = dependency

              name =
                case field do
                  %Field{ name: name } -> name
                  %VirtualField{ name: name } -> name
                end

              case type_conversion do
                TypeConversionUnspecified -> Bind.bind_managed_value(name, __MODULE__)
                TypeConversionManaged -> Bind.bind_managed_value(name, __MODULE__)
                TypeConversionUnmanaged -> Bind.bind_unmanaged_value(name, __MODULE__)
                TypeConversionBinary-> Bind.bind_binary_value(name, __MODULE__)
              end

            %DependencyOnOption{} -> nil

          end

        end
      ) |> Enum.reject(&is_nil/1)

    quote do
      { unquote_splicing(output_binds) } <- unquote(virtual_fields_producing_checkpoint_function_name(index))(unquote_splicing(input_binds), options)
    end

  end


end
