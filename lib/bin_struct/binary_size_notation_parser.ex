defmodule BinStruct.BinarySizeNotationParser do

  @units %{
    "K" => 1024,
    "M" => 1024 * 1024,
    "G" => 1024 * 1024 * 1024
  }

  def parse_bytes_count(str) when is_binary(str) do
    case Regex.run(~r/^(\d+)([KMG]?)$/i, String.trim(str)) do
      [_, num, unit] ->
        value = String.to_integer(num)
        multiplier = Map.get(@units, String.upcase(unit), 1)
        value * multiplier

      _ ->
        raise ArgumentError, "Invalid size notation: #{inspect(str)}"
    end
  end

end
