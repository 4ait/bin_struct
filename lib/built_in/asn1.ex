defmodule BinStruct.BuiltIn.Asn1 do

  use BinStructCustomType

  def init_args(custom_type_args) do

    args = %{
      asn1_module: custom_type_args[:asn1_module],
      asn1_type: custom_type_args[:asn1_type]
    }

    case args do
      %{
        asn1_module: asn1_module,
        asn1_type: asn1_type
      } when is_atom(asn1_module) and is_atom(asn1_type) -> { :ok, args }
      _ -> { :error, "asn1_module and asn1_type arguments required by not provided"  }
    end

  end

  def parse_returning_options(bin, custom_type_args, opts) do

    %{
      asn1_module: asn1_module,
      asn1_type: asn1_type
    } = custom_type_args

    case asn1_module.decode(asn1_type, bin) do

      { :ok, decoded_asn1, "" } ->

        unmanaged_format_with_binary = { decoded_asn1, bin }

        { :ok, unmanaged_format_with_binary, "", opts}

      { :ok, decoded_asn1, rest_with_maybe_leading_bits_remainder } ->

        remainder_bits = Integer.mod(bit_size(rest_with_maybe_leading_bits_remainder), 8)

        <<_skip::bitstring-size(remainder_bits), rest::binary>> = rest_with_maybe_leading_bits_remainder

        parsed_bytes_count = byte_size(bin) - byte_size(rest)

        << bytes_parsed::size(parsed_bytes_count)-bytes, _rest::binary >> = bin

        unmanaged_format_with_binary = { decoded_asn1, bytes_parsed  }

        { :ok, unmanaged_format_with_binary, rest, opts }

      { :error, error } -> { :error, error }

    end

  end


  def size(data, _custom_type_args) do

    { _elixir_term, encoded_binary } = data

    byte_size(encoded_binary)

  end

  def dump_binary(data, _custom_type_args) do

    { _elixir_term, encoded_binary } = data

    encoded_binary

  end


  def known_total_size_bytes(_custom_type_args) do
    :unknown
  end


  def from_unmanaged_to_managed(unmanaged, _custom_type_args) do

    { elixir_term, _encoded_binary } = unmanaged

    elixir_term

  end

  def managed_to_unmanaged(managed, custom_type_args) do


    %{
      asn1_module: asn1_module,
      asn1_type: asn1_type
    } = custom_type_args

    case managed do

      { elixir_term, encoded_binary } -> { elixir_term, encoded_binary }

      elixir_term ->

        { :ok, encoded_binary } = asn1_module.encode(asn1_type, elixir_term)

        { elixir_term, encoded_binary }


    end

  end

end
