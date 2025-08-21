defmodule BinStructTest.MemorySizeLimitTests.TlsKnownSizeLimitTest do

  use ExUnit.Case

  @cert Path.expand("test_data/server.crt")
  @key  Path.expand("test_data/server.key")

  setup do
    Application.ensure_all_started(:ssl)

    {:ok, listen} =
      :gen_tcp.listen(0, [:binary, packet: :raw, active: false, reuseaddr: true, ip: {127,0,0,1}])

    {:ok, port} = :inet.port(listen)
    parent = self()

    server =
      Task.async(fn ->
        {:ok, tcp_sock} = :gen_tcp.accept(listen)

        ssl_opts = [
          certfile: @cert,
          keyfile: @key,
          reuse_sessions: false
        ]

        {:ok, ssl_sock} = :ssl.handshake(tcp_sock, ssl_opts, 5_000)

        # Send a 2MB payload
        payload = :binary.copy(<<0>>, 2 * 1024 * 1024)
        :ok = :ssl.send(ssl_sock, payload)
        :ssl.close(ssl_sock)
        send(parent, :server_done)
      end)

    on_exit(fn ->
      ref = Process.monitor(server.pid)
      :gen_tcp.close(listen)

      receive do
        {:DOWN, ^ref, :process, _pid, _reason} -> :ok
      after
        200 -> :ok
      end
    end)

    {:ok, port: port}
  end


  test "tls receive known size limit works", %{port: port} do

    Application.put_env(:bin_struct, :enable_log_tls, false)
    Application.put_env(:bin_struct, :define_receive_send_tls, true)
    Application.put_env(:bin_struct, :tls_receive_max_buffer_size, "1M")

    Code.eval_quoted(quote do

      defmodule Struct do

        use BinStruct

        field :field_size_exceeds_limit, :binary, length: 2 * 1024 * 1024

      end

    end)


    {:ok, tls_socket} =
      :ssl.connect({127, 0, 0, 1}, port,
        [
          :binary,
          verify: :verify_none,
          active: false
        ]
      )

    error =
      assert_raise RuntimeError, fn ->
        Struct.tls_receive(tls_socket)
      end

    assert error.message =~ "exceeded limit"

  end



end
