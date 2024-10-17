defmodule BinStruct.Macro.Encoder do

  alias BinStruct.Macro.FlagsEncoderDecoder
  alias BinStruct.Macro.EnumEncoderDecoder

  def encode_term_to_bin_struct_field({:variant_of, _variants}, quoted), do: quoted
  def encode_term_to_bin_struct_field({:static_value, _value}, quoted), do: quoted

  def encode_term_to_bin_struct_field({:bool, %{ bit_size: bit_size }}, quoted) do

    quote do
      encode_bool(unquote(quoted), unquote(bit_size))
    end

  end

  def encode_term_to_bin_struct_field({:uint, %{ bit_size: bit_size, endianness: endianness} }, quoted) do


    case endianness do
      :big ->
        quote do
          encode_uint_variable_bit_size_be(unquote(quoted), unquote(bit_size))
        end

      :little ->
        quote do
          encode_uint_variable_bit_size_little(unquote(quoted), unquote(bit_size))
        end

      :none ->
        quote do
          encode_uint_variable_bit_size_none(unquote(quoted), unquote(bit_size))
        end
    end


  end

  def encode_term_to_bin_struct_field({:int, %{ bit_size: bit_size, endianness: endianness} }, quoted) do


    case endianness do
      :big ->
        quote do
          encode_int_variable_bit_size_be(unquote(quoted), unquote(bit_size))
        end

      :little ->
        quote do
          encode_int_variable_bit_size_little(unquote(quoted), unquote(bit_size))
        end

      :none ->
        quote do
          encode_int_variable_bit_size_none(unquote(quoted), unquote(bit_size))
        end
    end

  end

  def encode_term_to_bin_struct_field(:uint8, quoted) do

    quote do
      encode_uint8(unquote(quoted))
    end

  end

  def encode_term_to_bin_struct_field(:int8, quoted) do

    quote do
      encode_int8(unquote(quoted))
    end

  end


  def encode_term_to_bin_struct_field(:uint16_be, quoted) do

    quote do
      encode_uint16_be(unquote(quoted))
    end

  end

  def encode_term_to_bin_struct_field(:uint32_be, quoted) do

    quote do
      encode_uint32_be(unquote(quoted))
    end

  end

  def encode_term_to_bin_struct_field(:uint64_be, quoted) do

    quote do
      encode_uint64_be(unquote(quoted))
    end

  end


  def encode_term_to_bin_struct_field(:int8_be, quoted) do

    quote do
      encode_int8_be(unquote(quoted))
    end

  end

  def encode_term_to_bin_struct_field(:int16_be, quoted) do

    quote do
      encode_int16_be(unquote(quoted))
    end

  end

  def encode_term_to_bin_struct_field(:int32_be, quoted) do

    quote do
      encode_int32_be(unquote(quoted))
    end

  end

  def encode_term_to_bin_struct_field(:int64_be, quoted) do

    quote do
      encode_int64_be(unquote(quoted))
    end

  end

  def encode_term_to_bin_struct_field(:float32_be, quoted) do

    quote do
      encode_float32_be(unquote(quoted))
    end

  end

  def encode_term_to_bin_struct_field(:float64_be, quoted) do

    quote do
      encode_float64_be(unquote(quoted))
    end

  end


  def encode_term_to_bin_struct_field(:uint16_le, quoted) do

    quote do
      encode_uint16_le(unquote(quoted))
    end

  end

  def encode_term_to_bin_struct_field(:uint32_le, quoted) do

    quote do
      encode_uint32_le(unquote(quoted))
    end

  end

  def encode_term_to_bin_struct_field(:uint64_le, quoted) do

    quote do
      encode_uint64_le(unquote(quoted))
    end

  end


  def encode_term_to_bin_struct_field(:int16_le, quoted) do

    quote do
      encode_int16_le(unquote(quoted))
    end

  end

  def encode_term_to_bin_struct_field(:int32_le, quoted) do

    quote do
      encode_int32_le(unquote(quoted))
    end

  end

  def encode_term_to_bin_struct_field(:int64_le, quoted) do

    quote do
      encode_int64_le(unquote(quoted))
    end

  end

  def encode_term_to_bin_struct_field(:float32_le, quoted) do

    quote do
      encode_float32_le(unquote(quoted))
    end

  end

  def encode_term_to_bin_struct_field(:float64_le, quoted) do

    quote do
      encode_float64_le(unquote(quoted))
    end

  end

  def encode_term_to_bin_struct_field(:binary, quoted), do: quoted
  def encode_term_to_bin_struct_field({:module, _module}, quoted), do: quoted


  def encode_term_to_bin_struct_field({:asn1, asn1_info}, quoted) do

    %{
      module: asn1_module,
      type: asn1_type
    } = asn1_info

    quote do

      asn1_data = unquote(quoted)

      { :ok, binary } = unquote(asn1_module).encode(unquote(asn1_type), asn1_data)

      %{
        binary: binary,
        asn1_data: asn1_data
      }

    end

  end

  def encode_term_to_bin_struct_field({:list_of, %{ item_type: item_type} = _list_of_info}, quoted) do


    item_binding = { :item, [], __MODULE__ }

    item_encode_expr = encode_term_to_bin_struct_field(item_type, item_binding)

    quote do
      Enum.map(
        unquote(quoted),
        fn unquote(item_binding) -> unquote(item_encode_expr)  end
      )
    end

  end

  def encode_term_to_bin_struct_field({:flags, %{} = _flags_info} = flags_type, quoted) do
    FlagsEncoderDecoder.encode_term_to_bin_struct_field(flags_type, quoted)
  end

  def encode_term_to_bin_struct_field({:enum, %{} = _enum_info} = enum_type, quoted) do
    EnumEncoderDecoder.encode_term_to_bin_struct_field(enum_type, quoted)
  end

  def encode_term_to_bin_struct_field(:unmanaged, quoted), do: quoted

  def decode_bin_struct_field_to_term({:static_value, %{ bin_struct: bin_struct }}, _quoted), do: Macro.escape(bin_struct)
  def decode_bin_struct_field_to_term({:static_value, %{ value: value }}, _quoted), do: value

  def decode_bin_struct_field_to_term({:bool, %{ bit_size: bit_size }}, quoted) do

    quote do
      decode_bool(unquote(quoted), unquote(bit_size))
    end

  end


  def decode_bin_struct_field_to_term({:uint, %{ bit_size: bit_size, endianness: endianness} }, quoted) do


    case endianness do
      :big ->
        quote do
          decode_uint_variable_bit_size_be(unquote(quoted), unquote(bit_size))
        end

      :little ->
        quote do
          decode_uint_variable_bit_size_little(unquote(quoted), unquote(bit_size))
        end

      :none ->
        quote do
          decode_uint_variable_bit_size_none(unquote(quoted), unquote(bit_size))
        end
    end

  end

  def decode_bin_struct_field_to_term({:int, %{ bit_size: bit_size, endianness: endianness} }, quoted) do


    case endianness do
      :big ->
        quote do
          decode_int_variable_bit_size_be(unquote(quoted), unquote(bit_size))
        end

      :little ->
        quote do
          decode_int_variable_bit_size_little(unquote(quoted), unquote(bit_size))
        end

      :none ->
        quote do
          decode_int_variable_bit_size_none(unquote(quoted), unquote(bit_size))
        end
    end

  end

  def decode_bin_struct_field_to_term(:uint8, quoted) do

    quote do
      decode_uint8(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:int8, quoted) do

    quote do
      decode_int8(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:uint16_be, quoted) do

    quote do
      decode_uint16_be(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:uint32_be, quoted) do

    quote do
      decode_uint32_be(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:uint64_be, quoted) do

    quote do
      decode_uint64_be(unquote(quoted))
    end

  end


  def decode_bin_struct_field_to_term(:int16_be, quoted) do

    quote do
      decode_int16_be(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:int32_be, quoted) do

    quote do
      decode_int32_be(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:int64_be, quoted) do

    quote do
      decode_int64_be(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:float32_be, quoted) do

    quote do
      decode_float32_be(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:float64_be, quoted) do

    quote do
      decode_float64_be(unquote(quoted))
    end

  end


  def decode_bin_struct_field_to_term(:uint16_le, quoted) do

    quote do
      decode_uint16_le(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:uint32_le, quoted) do

    quote do
      decode_uint32_le(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:uint64_le, quoted) do

    quote do
      decode_uint64_le(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:int16_le, quoted) do

    quote do
      decode_int16_le(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:int32_le, quoted) do

    quote do
      decode_int32_le(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:int64_le, quoted) do

    quote do
      decode_int64_le(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:float32_le, quoted) do

    quote do
      decode_float32_le(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:float64_le, quoted) do

    quote do
      decode_float64_le(unquote(quoted))
    end

  end

  def decode_bin_struct_field_to_term(:binary, quoted), do: quoted


  def decode_bin_struct_field_to_term({:asn1, %{} = asn1_info}, quoted) do

    %{
      module: asn1_module,
      type: asn1_type
    } = asn1_info

    quote do

      case unquote(quoted) do

        %{ asn1_data: asn1_data } when not is_nil(asn1_data) -> asn1_data

        %{ asn1_data: nil, binary: binary} ->

          { :ok, asn1_data, "" } = unquote(asn1_module).decode(unquote(asn1_type), binary)

          asn1_data

      end

    end

  end

  def decode_bin_struct_field_to_term({:module, _module_info}, quoted), do: quoted

  def decode_bin_struct_field_to_term({:flags, %{} = _flags_info} = flags_type, quoted) do
    FlagsEncoderDecoder.decode_bin_struct_field_to_term(flags_type, quoted)
  end

  def decode_bin_struct_field_to_term({:enum, %{} = _enum_info} = enum_type, quoted) do
    EnumEncoderDecoder.decode_bin_struct_field_to_term(enum_type, quoted)
  end

  def decode_bin_struct_field_to_term({:variant_of, _variants}, quoted), do: quoted
  def decode_bin_struct_field_to_term({:list_of, _item_type}, quoted), do: quoted

  def decode_bin_struct_field_to_term(:unmanaged, quoted), do: quoted

  
end