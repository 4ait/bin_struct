defmodule BinStruct.Macro.EnumEncoderDecoder do

  alias BinStruct.Macro.Common
  alias BinStruct.Macro.Encoder

  def encode_term_to_bin_struct_field({:enum, %{} = enum_info}, quoted) do

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
        Encoder.encode_term_to_bin_struct_field(enum_representation_type, matched_enum_name_access)
      )

    end

  end


  def decode_bin_struct_field_to_term({:enum, %{} = enum_info}, quoted) do

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
          Encoder.decode_bin_struct_field_to_term(enum_representation_type, binary_value_access)
        )

      case enum_value do
        unquote(case_patterns)
      end

    end

  end


end