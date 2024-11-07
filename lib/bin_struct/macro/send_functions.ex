defmodule BinStruct.Macro.SendFunctions do


  def tcp_send() do

    quote do

      def tcp_send(bin_struct, socket) do

        binary = __MODULE__.dump_binary(bin_struct)

        Logger.debug("Sent TCP #{__MODULE__}: #{inspect(binary, limit: :infinity)}", ansi_color: :blue)

        :gen_tcp.send(socket, binary)

      end

    end

  end


  def tls_send() do

    quote do

      def tls_send(bin_struct, socket) do

        binary = __MODULE__.dump_binary(bin_struct)

        Logger.debug("Sent TLS #{__MODULE__}: #{inspect(binary, limit: :infinity)}", ansi_color: :light_blue)

        :ssl.send(socket, binary)

      end

    end

  end

end