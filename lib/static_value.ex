defmodule BinStructStaticValue do

  def uint8(value) do
    <<value::8-unsigned>>
  end

  def uint16_le(value) do
    <<value::16-little-unsigned>>
  end

  def uint16_be(value) do
    <<value::16-big-unsigned>>
  end

  def uint32_le(value) do
    <<value::32-little-unsigned>>
  end

  def uint32_be(value) do
    <<value::32-big-unsigned>>
  end

  def uint64_le(value) do
    <<value::64-little-unsigned>>
  end

  def uint64_be(value) do
    <<value::64-big-unsigned>>
  end

end
