defmodule BinStruct.Macro.TypeConverterToBinary do

  alias BinStruct.Macro.TypeConverters.FlagsTypeConverter
  alias BinStruct.Macro.TypeConverters.EnumTypeConverter
  alias BinStruct.Macro.TypeConverters.ListOfTypeConverter
  alias BinStruct.Macro.TypeConverters.StaticValueTypeConverter
  alias BinStruct.Macro.TypeConverters.VariantOfTypeConverter
  alias BinStruct.Macro.TypeConverters.ModuleTypeConverter
  alias BinStruct.Macro.TypeConverters.PrimitiveTypeConverter

  def convert_unmanaged_value_to_binary({:static_value, _value} = static_value_type, _quoted) do
    StaticValueTypeConverter.from_unmanaged_to_binary_static_value(static_value_type)
  end

  def convert_unmanaged_value_to_binary({:bool, %{ bit_size: bit_size }}, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_bool(quoted, bit_size)
  end

  def convert_unmanaged_value_to_binary({:uint, %{ bit_size: bit_size, endianness: endianness} }, quoted) do

    case endianness do
      :big ->
        PrimitiveTypeConverter.from_unmanaged_to_binary_uint_variable_bit_size_be(quoted, bit_size)

      :little ->
        PrimitiveTypeConverter.from_unmanaged_to_binary_uint_variable_bit_size_le(quoted, bit_size)

      :none ->
        PrimitiveTypeConverter.from_unmanaged_to_binary_uint_variable_bit_size_none(quoted, bit_size)

    end

  end

  def convert_unmanaged_value_to_binary({:int, %{ bit_size: bit_size, endianness: endianness} }, quoted) do

    case endianness do
      :big ->
        PrimitiveTypeConverter.from_unmanaged_to_binary_int_variable_bit_size_be(quoted, bit_size)

      :little ->
        PrimitiveTypeConverter.from_unmanaged_to_binary_int_variable_bit_size_le(quoted, bit_size)

      :none ->
        PrimitiveTypeConverter.from_unmanaged_to_binary_int_variable_bit_size_none(quoted, bit_size)

    end

  end

  def convert_unmanaged_value_to_binary(:uint8, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_uint8(quoted)
  end

  def convert_unmanaged_value_to_binary(:int8, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_int8(quoted)
  end

  def convert_unmanaged_value_to_binary(:uint16_be, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_uint16_be(quoted)
  end

  def convert_unmanaged_value_to_binary(:uint32_be, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_uint32_be(quoted)
  end

  def convert_unmanaged_value_to_binary(:uint64_be, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_uint64_be(quoted)
  end

  def convert_unmanaged_value_to_binary(:int16_be, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_int16_be(quoted)
  end

  def convert_unmanaged_value_to_binary(:int32_be, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_int32_be(quoted)
  end

  def convert_unmanaged_value_to_binary(:int64_be, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_int64_be(quoted)
  end

  def convert_unmanaged_value_to_binary(:float32_be, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_float32_be(quoted)
  end

  def convert_unmanaged_value_to_binary(:float64_be, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_float64_be(quoted)
  end

  def convert_unmanaged_value_to_binary(:uint16_le, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_uint16_le(quoted)
  end

  def convert_unmanaged_value_to_binary(:uint32_le, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_uint32_le(quoted)
  end

  def convert_unmanaged_value_to_binary(:uint64_le, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_uint64_le(quoted)
  end

  def convert_unmanaged_value_to_binary(:int16_le, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_int16_le(quoted)
  end

  def convert_unmanaged_value_to_binary(:int32_le, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_int32_le(quoted)
  end

  def convert_unmanaged_value_to_binary(:int64_le, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_int64_le(quoted)
  end

  def convert_unmanaged_value_to_binary(:float32_le, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_float32_le(quoted)
  end

  def convert_unmanaged_value_to_binary(:float64_le, quoted) do
    PrimitiveTypeConverter.from_unmanaged_to_binary_float64_le(quoted)
  end

  def convert_unmanaged_value_to_binary(:binary, quoted), do: quoted

  def convert_unmanaged_value_to_binary({:module, _module_info} = module_type, quoted) do
    ModuleTypeConverter.from_unmanaged_to_binary_module(module_type, quoted)
  end

  def convert_unmanaged_value_to_binary({:flags, %{} = _flags_info} = flags_type, quoted) do
    FlagsTypeConverter.from_unmanaged_to_binary_flags(flags_type, quoted)
  end

  def convert_unmanaged_value_to_binary({:enum, %{} = _enum_info} = enum_type, quoted) do
    EnumTypeConverter.from_unmanaged_to_binary_enum(enum_type, quoted)
  end

  def convert_unmanaged_value_to_binary({:variant_of, _variants} = variant_of_type, quoted) do
    VariantOfTypeConverter.from_unmanaged_to_binary_variant_of(variant_of_type, quoted)
  end

  def convert_unmanaged_value_to_binary({:list_of, _list_of_info} = list_of_type , quoted) do
    ListOfTypeConverter.from_unmanaged_to_binary_list_of(list_of_type, quoted)
  end

  def convert_unmanaged_value_to_binary(:unspecified, quoted), do: quoted

end