defmodule BinStructTest.MemorySizeLimitTests.TcpDynamicSizeLimitTest do
  use ExUnit.Case

  setup do
    {:ok, listen} =
      :gen_tcp.listen(0, [:binary, packet: :raw, active: false, reuseaddr: true, ip: {127, 0, 0, 1}])

    {:ok, port} = :inet.port(listen)
    parent = self()

    server =
      Task.async(fn ->
        {:ok, sock} = :gen_tcp.accept(listen)

        # Send a 2MB payload
        payload = :binary.copy(<<0>>, 2 * 1024 * 1024)
        :ok = :gen_tcp.send(sock, payload)
        :gen_tcp.close(sock)
        send(parent, :server_done)
      end)

    on_exit(fn ->
      # Unblock accept/ensure task can finish
      ref = Process.monitor(server.pid)
      :gen_tcp.close(listen)

      # Wait briefly for the task to go down (don’t use Task.shutdown here)
      receive do
        {:DOWN, ^ref, :process, _pid, _reason} -> :ok
      after
        200 -> :ok
      end
    end)

    {:ok, port: port}
  end

  test "tcp receive dynamic size limit works", %{port: port} do
    # Enable BinStruct TCP helpers and set max buffer to 1MB
    Application.put_env(:bin_struct, :enable_log_tcp, false)
    Application.put_env(:bin_struct, :define_receive_send_tcp, true)
    Application.put_env(:bin_struct, :tcp_receive_max_buffer_size, "1M")

    # Define the Struct dynamically with a length_by/0 callback that returns 2MB
    Code.eval_quoted(quote do
      defmodule Struct do
        use BinStruct

        register_callback &length_by/0

        field :field_size_exceeds_limit, :binary, length_by: &length_by/0

        defp length_by(), do: 2 * 1024 * 1024
      end
    end)

    {:ok, tcp_socket} =
      :gen_tcp.connect({127, 0, 0, 1}, port, [:binary, active: false], 2_000)

    error =
      assert_raise RuntimeError, fn ->
        Struct.tcp_receive(tcp_socket)
      end

    assert error.message =~ "exceeded limit"
  end
end
