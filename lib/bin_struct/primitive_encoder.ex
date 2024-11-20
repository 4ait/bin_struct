defmodule BinStruct.PrimitiveEncoder do

  @moduledoc """

    Useful in registered_callbacks when library can't achieve automatic type conversion.

    ```
      <<1>> = BinStruct.PrimitiveEncoder.uint8(1)
    ```

  """

  def uint8(value), do: <<value::8-unsigned>>
  def uint16_le(value), do: <<value::16-little-unsigned>>
  def uint16_be(value), do: <<value::16-big-unsigned>>
  def uint32_le(value), do: <<value::32-little-unsigned>>
  def uint32_be(value), do: <<value::32-big-unsigned>>
  def uint64_le(value), do: <<value::64-little-unsigned>>
  def uint64_be(value), do: <<value::64-big-unsigned>>

  def uint_le(value, bit_size), do: <<value::size(bit_size)-little-unsigned>>
  def uint_be(value, bit_size), do: <<value::size(bit_size)-big-unsigned>>

  def int8(value), do: <<value::8-signed>>
  def int16_le(value), do: <<value::16-little-signed>>
  def int16_be(value), do: <<value::16-big-signed>>
  def int32_le(value), do: <<value::32-little-signed>>
  def int32_be(value), do: <<value::32-big-signed>>
  def int64_le(value), do: <<value::64-little-signed>>
  def int64_be(value), do: <<value::64-big-signed>>

  def int_le(value, bit_size), do: <<value::size(bit_size)-little-signed>>
  def int_be(value, bit_size), do: <<value::size(bit_size)-big-signed>>

  def float32_le(value), do: <<value::32-little-float>>
  def float32_be(value), do: <<value::32-big-float>>
  def float64_le(value), do: <<value::64-little-float>>
  def float64_be(value), do: <<value::64-big-float>>

  def bool(value, bit_size \\ 8) do
    integer_value = case value do
      true -> 1
      false -> 0
    end
    <<integer_value::size(bit_size)-integer-big-unsigned>>
  end

end



