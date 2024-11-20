defmodule BinStruct.Macro.Structs.FieldsMap do

  @moduledoc false

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

    case fields_map do
      %{ ^field_name => field } -> field
      _ -> raise "Field name: #{inspect(field_name)} was requested, but not exists"
    end

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
