defmodule BinStruct.ParseDynamicTerminated do

  def parse_dynamic_terminated(bin, termination, acc \\ <<>>)

  def parse_dynamic_terminated(<<term::binary-size(2), rest::binary>>, termination, acc)
      when term == termination
    do
    { :ok, acc, rest }
  end

  def parse_dynamic_terminated(<<byte::bytes-(1), rest::binary>>, termination, acc) do
    parse_dynamic_terminated(rest, termination, <<acc::binary, byte::binary>>)
  end

  def parse_dynamic_terminated(_, _, _) do
    :not_enough_bytes
  end

end


