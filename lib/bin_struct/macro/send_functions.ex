defmodule BinStruct.Macro.SendFunctions do

  @moduledoc false

  def tcp_send(enable_log_tcp) do

    quote do

      def tcp_send(bin_struct, socket) do

        binary = __MODULE__.dump_binary(bin_struct)

        unquote_splicing(
          case enable_log_tcp do
            true ->

              [
                quote do
                  Logger.debug("Sent TCP #{__MODULE__}: #{inspect(binary, limit: :infinity)}", ansi_color: :blue)
                end
              ]

            false -> []
          end
        )


        :gen_tcp.send(socket, binary)

      end

    end

  end


  def tls_send(enable_log_tls) do

    quote do

      def tls_send(bin_struct, socket) do

        binary = __MODULE__.dump_binary(bin_struct)

        unquote_splicing(
          case enable_log_tls do
            true ->

              [
                quote do
                  Logger.debug("Sent TLS #{__MODULE__}: #{inspect(binary, limit: :infinity)}", ansi_color: :light_blue)
                end
              ]

            false -> []
          end
        )


        :ssl.send(socket, binary)

      end

    end

  end

end