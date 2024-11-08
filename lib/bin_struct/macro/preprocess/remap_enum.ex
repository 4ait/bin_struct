defmodule BinStruct.Macro.Preprocess.RemapEnum do

  alias BinStruct.Macro.Preprocess.RemapType

  def remap_enum({:enum, enum_info_ast}, opts, env) do

    {:%{}, _meta, [type: enum_representation_type, values: enum_values]} = enum_info_ast

    { enum_values, _binding } = Code.eval_quoted(enum_values, [], env)

    enum_representation_type = RemapType.remap_type(enum_representation_type, opts, env)

    values =
      Enum.map(
        enum_values,
        fn { enum_value, enum_name } ->

          %{
            enum_value: enum_value,
            enum_name: enum_name
          }

        end
      )

    { :enum,
      %{
        type: enum_representation_type,
        values: values
      }
    }

  end

end