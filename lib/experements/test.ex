defmodule StructWithVirtualFields do

  use BinStruct

  register_callback &read_open_or_close_enum/1,
                    number: %{ type: :field, type_conversion: :unmanaged }

  register_callback &read_bool_flag/1,
                    open_or_close_enum: :field

  virtual :open_or_close_enum, {
    :enum,
    %{
      type: :uint8,
      values: [
        { 0x00, :closed },
        { 0x01, :open },
      ]
    }
  }, read_by: &read_open_or_close_enum/1

  virtual :open_or_close_flag, :unspecified, read_by: &read_bool_flag/1

  field :number, :uint8

  defp read_open_or_close_enum(number), do: number

  defp read_bool_flag(open_or_close_enum) do

    IO.inspect(open_or_close_enum)

    nil

  end

end
