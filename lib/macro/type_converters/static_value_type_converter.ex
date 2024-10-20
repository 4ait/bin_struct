defmodule BinStruct.Macro.TypeConverters.StaticValueTypeConverter do


  def from_managed_to_unmanaged_static_value({ :static_value, _value }) do


  end


  def from_unmanaged_to_managed_static_value({ :static_value, _value }) do

    #
    #def convert_unmanaged_value_to_managed({:static_value, %{ bin_struct: bin_struct }}, _quoted), do: Macro.escape(bin_struct)
    #def convert_unmanaged_value_to_managed({:static_value, %{ value: value }}, _quoted), do: value

    #bin_struct
    #Macro.escape(bin_struct)

  end

end