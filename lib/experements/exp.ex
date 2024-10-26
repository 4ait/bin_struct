defmodule StructWithVirtualFields do

  use BinStruct

  register_callback &mac_builder/2,
                    mac_algo: :field,
                    payload: :field

  register_callback &mac_length_builder/1,
                    mac: :field

  register_callback &mac_length/1,
                    mac_length: :field

  virtual :mac_algo, :unspecified, default: :none

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