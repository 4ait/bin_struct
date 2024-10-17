defmodule BinStruct.ParseDynamicTerminated do

  def parse_dynamic_terminated(bin, termination, acc \\ <<>>)

  def parse_dynamic_terminated(bin, termination, acc) do

    term_size = byte_size(termination)

    case bin do

      <<term::binary-size(^term_size), rest::binary>> when term == termination ->
        {:ok, acc, rest}

      <<byte::binary-size(1), rest::binary>> ->
        parse_dynamic_terminated(rest, termination, <<acc::binary, byte::binary>>)

      _ ->
        :not_enough_bytes
    end

  end



end


