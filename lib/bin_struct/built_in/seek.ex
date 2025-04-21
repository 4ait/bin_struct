defmodule BinStruct.BuiltIn.Seek do

  use BinStructCustomType

  def init_args(custom_type_args) do

    args = %{
      count: custom_type_args[:count]
    }

    case args do
      %{ count: count } when is_integer(count) -> { :ok, args }
      _ -> { :error, ":count argument required but not provided" }
    end

  end

  def parse_returning_options(bin, custom_type_args, opts) do

    %{
      count: count
    } = custom_type_args

    if byte_size(bin) >= count do

      <<seek::binary-size(count), _rest::binary>> = bin

      { :ok, seek, bin, opts  }

    else
      :not_enough_bytes
    end

  end

  def size(_data, _custom_type_args), do: 0
  def dump_binary(_data, _custom_type_args), do: <<>>

  def known_total_size_bytes(_custom_type_args), do: :unknown

  def from_unmanaged_to_managed(unmanaged, _custom_type_args), do: unmanaged
  def from_managed_to_unmanaged(managed, _custom_type_args), do: managed

end
