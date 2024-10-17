defmodule BinStruct.Macro.DumpIoDataFunction do


  def dump_io_data(_fields, _env) do

    quote do
      def dump_io_data(args), do: dump_binary(args)
    end

  end

end