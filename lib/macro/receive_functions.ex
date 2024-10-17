defmodule BinStruct.Macro.ReceiveFunctions do

  def tpc_receive_function_known_size(known_size_bytes) do

    quote do

      unquote(try_parse_from_tcp_data_function())

      def tcp_receive(tcp_socket, buffer \\ <<>>, options \\ nil) do

        known_total_size_bytes = unquote(known_size_bytes)

        available_in_buffer_size = byte_size(buffer)

        if available_in_buffer_size >= known_total_size_bytes do

          case try_parse_from_tcp_data(buffer, options) do
            {:ok, struct, rest } ->  {:ok, struct, rest }
          end

        else

          recv_count = known_total_size_bytes - available_in_buffer_size

          full_binary_for_struct =
            case :gen_tcp.recv(tcp_socket, recv_count) do
              { :ok, <<>> } -> raise "Received 0 bytes from socket, probably socket closed by peer"
              { :ok, received } -> <<buffer::binary, received::binary>>
            end

          case try_parse_from_tcp_data(full_binary_for_struct, options) do
            {:ok, struct, <<>> } ->  {:ok, struct, <<>> }
          end

        end

      end

    end

  end

  def tpc_receive_function_unknown_size() do

    quote do

      unquote(try_parse_from_tcp_data_function())

      def tcp_receive(tcp_socket, buffer \\ <<>>, options \\ nil) do

        case buffer do

          <<>> ->

            receive_more =
              case :gen_tcp.recv(tcp_socket, 0) do
                { :ok, <<>> } -> raise "Received 0 bytes from socket, probably socket closed by peer"
                { :ok, received } -> received
              end

            tcp_receive(tcp_socket, receive_more, options)

          buffer ->

            case try_parse_from_tcp_data(buffer, options) do

              { :ok, struct, rest } -> { :ok, struct, rest }

              :not_enough_bytes ->

                receive_more =
                  case :gen_tcp.recv(tcp_socket, 0) do
                    { :ok, <<>> } -> raise "Received 0 bytes from socket, probably socket closed by peer"
                    { :ok, received } -> received
                  end

                new_received_combined_with_buffer = <<buffer::binary, receive_more::binary>>

                tcp_receive(tcp_socket, new_received_combined_with_buffer, options)

            end

        end

      end

    end

  end

  def tls_receive_function_known_size(known_size_bytes) do

    quote do

      unquote(try_parse_from_tls_data_function())

      def tls_receive(tcp_socket, buffer \\ <<>>, options \\ nil) do

        known_total_size_bytes = unquote(known_size_bytes)

        available_in_buffer_size = byte_size(buffer)

        if available_in_buffer_size >= known_total_size_bytes do

          case try_parse_from_tls_data(buffer, options) do
            {:ok, struct, rest } ->  {:ok, struct, rest }
          end

        else

          recv_count = known_total_size_bytes - available_in_buffer_size

          full_binary_for_struct =
            case :ssl.recv(tcp_socket, recv_count) do
              { :ok, <<>> } -> raise "Received 0 bytes from socket, probably socket closed by peer"
              { :ok, received } -> <<buffer::binary, received::binary>>
            end

          case try_parse_from_tls_data(full_binary_for_struct, options) do
            {:ok, struct, <<>> } ->  {:ok, struct, <<>> }
          end

        end

      end

    end

  end

  def tls_receive_function_unknown_size() do

    quote do

      unquote(try_parse_from_tls_data_function())

      def tls_receive(tcp_socket, buffer \\ <<>>, options \\ nil) do

        case buffer do

          <<>> ->

            receive_more =
              case :ssl.recv(tcp_socket, 0) do
                { :ok, <<>> } -> raise "Received 0 bytes from socket, probably socket closed by peer"
                { :ok, received } -> received
              end

            tls_receive(tcp_socket, receive_more, options)

          buffer ->

            case try_parse_from_tls_data(buffer, options) do

              { :ok, struct, rest } -> { :ok, struct, rest }

              :not_enough_bytes ->

                receive_more =
                  case :ssl.recv(tcp_socket, 0) do
                    { :ok, <<>> } -> raise "Received 0 bytes from socket, probably socket closed by peer"
                    { :ok, received } -> received
                  end

                new_received_combined_with_buffer = <<buffer::binary, receive_more::binary>>

                tls_receive(tcp_socket, new_received_combined_with_buffer, options)

            end

        end

      end

    end

  end


  defp try_parse_from_tcp_data_function() do

    quote do

      defp try_parse_from_tcp_data(bin, options) do

        Logger.debug("Receive TCP #{String.trim_leading("#{__MODULE__}", "Elixir.")}: #{inspect(bin, limit: :infinity)}", ansi_color: :green)

        case __MODULE__.parse(bin, options) do

          {:ok, struct, rest }  ->

            Logger.debug("Created struct %#{String.trim_leading("#{__MODULE__}", "Elixir.")}{}", ansi_color: :green)

            {:ok, struct, rest }

          :not_enough_bytes -> :not_enough_bytes

        end

      end

    end

  end

  defp try_parse_from_tls_data_function() do

    quote do

      defp try_parse_from_tls_data(bin, options) do

        Logger.debug("Receive TLS #{String.trim_leading("#{__MODULE__}", "Elixir.")}: #{inspect(bin, limit: :infinity)}", ansi_color: :light_green)

        case __MODULE__.parse(bin, options) do

          {:ok, struct, rest } ->

            Logger.debug("Created struct %#{String.trim_leading("#{__MODULE__}", "Elixir.")}{}", ansi_color: :light_green)

            {:ok, struct, rest }

          :not_enough_bytes -> :not_enough_bytes

        end

      end

    end

  end

end