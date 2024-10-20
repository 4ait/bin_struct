defmodule BinStruct.Macro.TypeConverters.StaticValueTypeConverter do


  def from_managed_to_unmanaged_static_value({ :static_value, static_value_info }) do

    %{ value: value } = static_value_info

    value

  end


  def from_unmanaged_to_managed_static_value({ :static_value, static_value_info }) do

    case static_value_info do
      %{ bin_struct: bin_struct } -> Macro.escape(bin_struct)
      %{ value: value } -> value
    end

  end

end