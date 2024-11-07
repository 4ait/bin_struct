defmodule BinStruct.Macro.Structs.FieldsMap do

  alias BinStruct.Macro.Structs.FieldsMap
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField

  defstruct [
    :fields_map
  ]

  def new(fields, env) do
    %FieldsMap{
      fields_map: fields_make_map(fields, env)
    }
  end

  def get_field_by_name(self, field_name) do

    %{ fields_map: fields_map } = self

    %{ ^field_name => field } = fields_map

    field

  end

  defp fields_make_map(fields, _env) do

    Enum.map(
      fields,
      fn field ->

        case field do

          %Field{} = field ->

            %Field{name: name} = field

            { name, field }

          %VirtualField{} = virtual_field ->

            %VirtualField{ name: name } = virtual_field

            { name, virtual_field }

        end

      end
    ) |> Enum.into(%{})

  end


end
