defmodule TestCustomType do

  use BinStructCustomType

  defstruct [
    :data
  ]

  #assuming we trying to implement custom type for binary terminated with zero

  def parse_returning_options(bin, custom_type_args, opts) do

    case parse_dynamic_terminated(bin, <<0>>) do

      { :ok, parsed, rest } -> { :ok, %TestCustomType{ data: parsed }, rest, opts  }
      :not_enough_bytes -> :not_enough_bytes
    end

  end

  def decode(%TestCustomType{ data: data }, custom_type_args, _opts), do: data

  def size(%TestCustomType{ data: data }, custom_type_args) do

    byte_size(data) + byte_size(<<0>>)

  end

  def dump_binary(%TestCustomType{ data: data }, custom_type_args) do
    <<data::binary>> <> <<0>>
  end


  def known_total_size_bytes(_custom_type_args) do
    :unknown
  end

  def is_custom_type_terminated(_custom_type_args) do
    true
  end

  defp parse_dynamic_terminated(bin, termination, acc \\ <<>>)

  defp parse_dynamic_terminated(bin, termination, acc) do

    term_size = byte_size(termination)

    case bin do

      <<term::binary-size(^term_size), rest::binary>> when term == termination -> {:ok, acc, rest}

      <<byte::binary-size(1), rest::binary>> ->
        parse_dynamic_terminated(rest, termination, <<acc::binary, byte::binary>>)

      _ -> :not_enough_bytes

    end

  end
end
