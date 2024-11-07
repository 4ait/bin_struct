defmodule BinStructTest.VirtualFieldSystem.WriteTest do

  use ExUnit.Case


  defmodule StructWithVirtualFields do

    use BinStruct

    @type mac_algo :: :"hmac-sha2-256" | :none

    register_callback &mac_builder/2,
                      mac_algo: :field,
                      payload: :field

    register_callback &mac_length_builder/1,
                      mac: :field

    register_callback &mac_length/1,
                      mac_length: :field


    virtual :mac_algo, { :unspecified, type: mac_algo() }, default: :none

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
        payload: <<1, 2, 3>>
      )


    dump = StructWithVirtualFields.dump_binary(struct)

    { :ok, parsed_struct } = StructWithVirtualFields.parse_exact(dump)

    values = StructWithVirtualFields.decode(parsed_struct)

    expected_mac = <<172, 37, 94, 214, 16, 222, 204, 2, 72, 189, 91, 66, 220, 149, 2, 30, 56, 44, 36, 165, 96, 218, 218, 207, 113, 47, 13, 5, 2, 156, 135, 133>>

    %{
      payload: <<1, 2, 3>>,
      mac_length: 32,
      mac: ^expected_mac
    } = values

  end

end

