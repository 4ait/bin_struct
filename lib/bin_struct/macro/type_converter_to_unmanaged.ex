defmodule BinStruct.Macro.TypeConverterToUnmanaged do

  @moduledoc false

  alias BinStruct.Macro.TypeConverters.FlagsTypeConverter
  alias BinStruct.Macro.TypeConverters.EnumTypeConverter
  alias BinStruct.Macro.TypeConverters.ListOfTypeConverter
  alias BinStruct.Macro.TypeConverters.StaticValueTypeConverter
  alias BinStruct.Macro.TypeConverters.VariantOfTypeConverter
  alias BinStruct.Macro.TypeConverters.ModuleTypeConverter
  alias BinStruct.Macro.TypeConverters.PrimitiveTypeConverter

  def convert_managed_value_to_unmanaged({:variant_of, _variants} = variant_of_type, quoted) do
    VariantOfTypeConverter.from_managed_to_unmanaged_variant_of(variant_of_type, quoted)
  end

  def convert_managed_value_to_unmanaged({:static_value, _value} = static_value_type, _quoted) do
    StaticValueTypeConverter.from_managed_to_unmanaged_static_value(static_value_type)
  end

  def convert_managed_value_to_unmanaged({:bool, %{ bit_size: bit_size }}, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_bool(quoted, bit_size)
  end

  def convert_managed_value_to_unmanaged({:uint, %{ bit_size: bit_size, endianness: endianness} }, quoted) do

    case endianness do
      :big ->
        PrimitiveTypeConverter.from_managed_to_unmanaged_uint_variable_bit_size_be(quoted, bit_size)

      :little ->
        PrimitiveTypeConverter.from_managed_to_unmanaged_uint_variable_bit_size_le(quoted, bit_size)

      :none ->
        PrimitiveTypeConverter.from_managed_to_unmanaged_uint_variable_bit_size_none(quoted, bit_size)
    end


  end

  def convert_managed_value_to_unmanaged({:int, %{ bit_size: bit_size, endianness: endianness} }, quoted) do

    case endianness do
      :big ->
        PrimitiveTypeConverter.from_managed_to_unmanaged_int_variable_bit_size_be(quoted, bit_size)

      :little ->
        PrimitiveTypeConverter.from_managed_to_unmanaged_int_variable_bit_size_le(quoted, bit_size)

      :none ->
        PrimitiveTypeConverter.from_managed_to_unmanaged_int_variable_bit_size_none(quoted, bit_size)
    end

  end

  def convert_managed_value_to_unmanaged(:uint8, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_uint8(quoted)
  end

  def convert_managed_value_to_unmanaged(:int8, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_int8(quoted)
  end


  def convert_managed_value_to_unmanaged(:uint16_be, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_uint16_be(quoted)
  end

  def convert_managed_value_to_unmanaged(:uint32_be, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_uint32_be(quoted)
  end

  def convert_managed_value_to_unmanaged(:uint64_be, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_uint64_be(quoted)
  end


  def convert_managed_value_to_unmanaged(:int8_be, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_int8(quoted)
  end

  def convert_managed_value_to_unmanaged(:int16_be, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_int16_be(quoted)
  end

  def convert_managed_value_to_unmanaged(:int32_be, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_int32_be(quoted)
  end

  def convert_managed_value_to_unmanaged(:int64_be, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_int64_be(quoted)
  end

  def convert_managed_value_to_unmanaged(:float32_be, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_float32_be(quoted)
  end

  def convert_managed_value_to_unmanaged(:float64_be, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_float64_be(quoted)
  end


  def convert_managed_value_to_unmanaged(:uint16_le, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_uint16_le(quoted)
  end

  def convert_managed_value_to_unmanaged(:uint32_le, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_uint32_le(quoted)
  end

  def convert_managed_value_to_unmanaged(:uint64_le, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_uint64_le(quoted)
  end


  def convert_managed_value_to_unmanaged(:int16_le, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_int16_le(quoted)
  end

  def convert_managed_value_to_unmanaged(:int32_le, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_int32_le(quoted)
  end

  def convert_managed_value_to_unmanaged(:int64_le, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_int64_le(quoted)
  end

  def convert_managed_value_to_unmanaged(:float32_le, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_float32_le(quoted)
  end

  def convert_managed_value_to_unmanaged(:float64_le, quoted) do
    PrimitiveTypeConverter.from_managed_to_unmanaged_float64_le(quoted)
  end

  def convert_managed_value_to_unmanaged(:binary, quoted), do: quoted

  def convert_managed_value_to_unmanaged({:module, _module} = module_type, quoted) do
    ModuleTypeConverter.from_managed_to_unmanaged_module(module_type, quoted)
  end

  def convert_managed_value_to_unmanaged({:list_of, _list_of_info } = list_of_type, quoted) do
    ListOfTypeConverter.from_managed_to_unmanaged_list_of(list_of_type, quoted)
  end

  def convert_managed_value_to_unmanaged({:flags, %{} = _flags_info} = flags_type, quoted) do
    FlagsTypeConverter.from_managed_to_unmanaged_flags(flags_type, quoted)
  end

  def convert_managed_value_to_unmanaged({:enum, %{} = _enum_info} = enum_type, quoted) do
    EnumTypeConverter.from_managed_to_unmanaged_enum(enum_type, quoted)
  end

  def convert_managed_value_to_unmanaged(:unspecified, quoted), do: quoted

end