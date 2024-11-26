defmodule BinStruct.Macro.Decode.DecodeFieldFunction do

  @moduledoc false

  def decode_field_function_implemented_via_decode_all(_env) do

    quote do

      def decode_field(%__MODULE__{} = struct, field_name_atom) do

        %{
          ^field_name_atom => value
        } = __MODULE__.decode(struct)

        value

      end

    end

  end

end
