defmodule BinStructTest.VirtualFieldSystem.WriteTest do

  use ExUnit.Case


  defmodule StructWithVirtualFields do

    use BinStruct

    register_callback &mac_builder/2,
                      mac_algo: :argument,
                      payload: :argument

    register_callback &mac_length_builder/1,
                      mac: :field

    register_callback &mac_length/1,
                      mac_length: :field

    virtual :mac_algo, :unmanaged, write: true, default: :none

    field :mac_length, :uint8,
          builder: &mac_length_builder/1

    field :mac, :binary,
          builder: &mac_builder/2,
          length_by: &mac_length/1

    field :payload, :binary

    defp mac_builder(:none, _payload), do: ""

    defp mac_builder(:"hmac-sha2-256", payload) do

      mac_key = "supersecretkey"

      :crypto.mac(:hmac, :sha256, mac_key, payload)

    end

    defp mac_length_builder(mac), do: byte_size(mac)

    defp mac_length(mac_length), do: mac_length

  end


  test "struct with virtual write works" do

    struct =
      StructWithVirtualFields.new(
        mac_algo: :"hmac-sha2-256",
        payload: <<123>>
      )

    dump = StructWithVirtualFields.dump_binary(struct)

    { :ok, parsed_struct } = StructWithVirtualFields.parse_exact(dump)

    values = StructWithVirtualFields.decode(parsed_struct)

    expected_mac = <<73, 45, 201, 166, 21, 7, 61, 65, 81, 2, 154, 165, 107, 109, 225, 68, 38, 52, 34, 56, 49, 224, 141, 247, 214, 166, 46, 5, 28, 62, 241, 165>>

    %{
      payload: <<123>>,
      mac_length: 32,
      mac: ^expected_mac
    } = values

  end

end

