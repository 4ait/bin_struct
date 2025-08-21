defmodule BinStruct.Macro.ReceiveFunctionsSizeValidation do

  @moduledoc false

  alias BinStruct.BinarySizeNotationParser

  def validate_tcp_known_size() do


    tcp_receive_max_buffer_size = Application.get_env(:bin_struct, :tcp_receive_max_buffer_size)

    if tcp_receive_max_buffer_size do

      buffer_size_limit_bytes = BinarySizeNotationParser.parse_bytes_count(tcp_receive_max_buffer_size)

      quote do

        defp validate_tcp_known_total_size_bytes_limit(known_total_size_bytes) do

          if known_total_size_bytes > unquote(buffer_size_limit_bytes) do
            raise "tcp_receive function for known size #{known_total_size_bytes} exceeded limit #{unquote(tcp_receive_max_buffer_size)}"
          end

          :ok

        end

      end

    else
      quote do
        defp validate_tcp_known_total_size_bytes_limit(_known_total_size_bytes), do: :ok
      end
    end

  end

  def validate_tls_known_size() do

    tls_receive_max_buffer_size = Application.get_env(:bin_struct, :tls_receive_max_buffer_size)

    if tls_receive_max_buffer_size do

      buffer_size_limit_bytes = BinarySizeNotationParser.parse_bytes_count(tls_receive_max_buffer_size)

      quote do

        defp validate_tls_known_total_size_bytes_limit(known_total_size_bytes) do

          if known_total_size_bytes > unquote(buffer_size_limit_bytes) do
            raise "tls_receive function for known size #{known_total_size_bytes} exceeded limit #{unquote(tls_receive_max_buffer_size)}"
          end

          :ok

        end

      end

    else
      quote do
        defp validate_tls_known_total_size_bytes_limit(_known_total_size_bytes), do: :ok
      end
    end

  end

  def validate_tcp_buffer_size_function() do

    tcp_receive_max_buffer_size = Application.get_env(:bin_struct, :tcp_receive_max_buffer_size)

    if tcp_receive_max_buffer_size do
      buffer_size_limit_bytes = BinarySizeNotationParser.parse_bytes_count(tcp_receive_max_buffer_size)

      quote do

        defp validate_tcp_buffer_size(buffer) do

          if byte_size(buffer) > unquote(buffer_size_limit_bytes) do
            raise "tcp_receive function buffer size exceeded limit #{unquote(tcp_receive_max_buffer_size)}, #{byte_size(buffer)} bytes in buffer."
          end

          :ok

        end

      end

    else
     quote do
       defp validate_tcp_buffer_size(_buffer), do: :ok
     end
    end

  end

  def validate_tls_buffer_size_function() do

    tls_receive_max_buffer_size = Application.get_env(:bin_struct, :tls_receive_max_buffer_size)

    if tls_receive_max_buffer_size do
      buffer_size_limit_bytes = BinarySizeNotationParser.parse_bytes_count(tls_receive_max_buffer_size)

      quote do

        defp validate_tls_buffer_size(buffer) do

          if byte_size(buffer) > unquote(buffer_size_limit_bytes) do

            raise "tls_receive function buffer size exceeded limit #{unquote(tls_receive_max_buffer_size)}, #{byte_size(buffer)} bytes in buffer."
          end

          :ok

        end

      end

    else

     quote do
       defp validate_tls_buffer_size(_buffer), do: :ok
     end

    end

  end

end