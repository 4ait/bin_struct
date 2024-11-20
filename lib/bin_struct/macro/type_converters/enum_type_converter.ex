defmodule BinStruct.Macro.TypeConverters.EnumTypeConverter do

  @moduledoc false

  alias BinStruct.Macro.Common
  alias BinStruct.Macro.TypeConverterToManaged
  alias BinStruct.Macro.TypeConverterToUnmanaged

  def from_managed_to_unmanaged_enum({ :enum, enum_info }, quoted) do

    %{
      type: enum_representation_type,
      values: values
    } = enum_info

    case_patterns =
      Enum.map(
        values,
        fn %{} = enum_variant ->

          %{
            enum_value: enum_value,
            enum_name: enum_name
          } = enum_variant

          Common.case_pattern(
            enum_name,
            enum_value
          )

        end
     )

    matched_enum_name_access = { :matched_enum_name_access, [], __MODULE__ }

    quote do

      value = unquote(quoted)

      unquote(matched_enum_name_access) =
        case value do
          unquote(case_patterns)
        end

      unquote(
        TypeConverterToUnmanaged.convert_managed_value_to_unmanaged(enum_representation_type, matched_enum_name_access)
      )

    end

  end


  def from_unmanaged_to_managed_enum({ :enum, enum_info }, quoted) do

    %{
      type: enum_representation_type,
      values: values
    } = enum_info

    case_patterns =
      Enum.map(
        values,
        fn %{} = enum_variant ->

          %{
            enum_value: enum_value,
            enum_name: enum_name
          } = enum_variant

          Common.case_pattern(
            enum_value,
            enum_name
          )

        end
      )

    binary_value_access = { :binary_value_access, [], __MODULE__ }

    quote do

      unquote(binary_value_access) = unquote(quoted)

      enum_value =
        unquote(
          TypeConverterToManaged.convert_unmanaged_value_to_managed(enum_representation_type, binary_value_access)
        )

      case enum_value do
        unquote(case_patterns)
      end

    end

  end


  def from_unmanaged_to_binary_enum({ :enum, _enum_info }, quoted), do: quoted


end