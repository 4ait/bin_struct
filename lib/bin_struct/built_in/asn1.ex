defmodule BinStruct.BuiltIn.Asn1 do

  @moduledoc """
  Asn1 is `BinStructCustomType` and it uses erlang [`asn1`](https://www.erlang.org/doc/apps/asn1/api-reference.html) compiler output as implementation.

  Asn1 modules and types can be compiled using this command

  ```bash
  erlc -o "$OUTPUT_DIR" -I "$OUTPUT_DIR" +noobj -bper +maps +undec_rest TEST-ASN1.asn1
  ```

  `+maps` is optional, change `-bper` to your target encoding (erlang compiler support BER, PER and so on)
  `+undec_rest` is required to current `BinStructCustomType` implementation,
  but this may be non-ideal and sometimes shadow errors in data, returning `:not_enough_bytes` instead


  ```elixir
  defmodule Struct do
    use BinStruct

    alias BinStruct.BuiltIn.Asn1

    field :asn1, { Asn1, asn1_module: :"TEST-ASN1", asn1_type: :"SimpleType" }
  end
  ```
  """

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
      _ -> { :error, "asn1_module and asn1_type arguments required but not provided"  }
    end

  end

  def parse_returning_options(bin, custom_type_args, opts) do

    %{
      asn1_module: asn1_module,
      asn1_type: asn1_type
    } = custom_type_args

    case asn1_module.decode(asn1_type, bin) do

      { :ok, decoded_asn1, "" } ->

        unmanaged_format_with_binary = to_unmanaged(decoded_asn1, bin)

        { :ok, unmanaged_format_with_binary, "", opts}

      { :ok, decoded_asn1, rest_with_maybe_leading_bits_remainder } ->

        remainder_bits = Integer.mod(bit_size(rest_with_maybe_leading_bits_remainder), 8)

        <<_skip::bitstring-size(remainder_bits), rest::binary>> = rest_with_maybe_leading_bits_remainder

        parsed_bytes_count = byte_size(bin) - byte_size(rest)

        << bytes_parsed::size(parsed_bytes_count)-bytes, _rest::binary >> = bin

        unmanaged_format_with_binary = to_unmanaged(decoded_asn1, bytes_parsed)

        { :ok, unmanaged_format_with_binary, rest, opts }

      { :error, error } ->

        case error do
          { :asn1, {  { :badmatch, _ }, _ } } -> :not_enough_bytes
          _ -> { :wrong_data, error }
        end

    end

  end


  def size(unmanaged, _custom_type_args) do

    { :__BinStructAsn1__, _elixir_term, encoded_binary } = unmanaged

    byte_size(encoded_binary)

  end

  def dump_binary(unmanaged, _custom_type_args) do

    { :__BinStructAsn1__, _elixir_term, encoded_binary } = unmanaged

    encoded_binary

  end


  def known_total_size_bytes(_custom_type_args) do
    :unknown
  end


  def from_unmanaged_to_managed(unmanaged, _custom_type_args) do

    { :__BinStructAsn1__, elixir_term, _encoded_binary } = unmanaged

    elixir_term

  end

  def from_managed_to_unmanaged(managed, custom_type_args) do

    %{
      asn1_module: asn1_module,
      asn1_type: asn1_type
    } = custom_type_args

    { :ok, encoded_binary } = asn1_module.encode(asn1_type, managed)

    to_unmanaged(managed, encoded_binary)

  end

  defp to_unmanaged(asn1, bin) do
    { :__BinStructAsn1__, asn1, bin }
  end

end
