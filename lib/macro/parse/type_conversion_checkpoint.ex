defmodule BinStruct.Macro.Parse.TypeConversionCheckpoint do

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

  def type_conversion_checkpoint_function(
        function_name,
        input_dependencies,
        output_dependencies,
        context
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

              Bind.bind_unmanaged_value(name, context)

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

              unmanaged_value_access = Bind.bind_unmanaged_value(name, context)

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


end
