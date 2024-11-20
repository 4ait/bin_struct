defmodule BinStruct.Macro.TypeConverters.StaticValueTypeConverter do

  @moduledoc false

  def from_managed_to_unmanaged_static_value({ :static_value, static_value_info }) do

    %{ value: value } = static_value_info

    value

  end


  def from_unmanaged_to_managed_static_value({ :static_value, static_value_info }) do

    %{ value: value } = static_value_info

    value

  end

  def from_unmanaged_to_binary_static_value({ :static_value, static_value_info }) do

    %{ value: value } = static_value_info

    value

  end

end