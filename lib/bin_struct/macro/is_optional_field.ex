defmodule BinStruct.Macro.IsOptionalField do

  @moduledoc false

  alias BinStruct.Macro.Structs.Field

  def is_optional_field( %Field{ opts: opts } ) do
    is_optional_by_opts(opts)
  end

  defp is_optional_by_opts(opts) do
    optional_by = (if opts[:optional_by], do: true, else: false)
    optional = (if opts[:optional], do: true, else: false)

    optional_by || optional

  end

end