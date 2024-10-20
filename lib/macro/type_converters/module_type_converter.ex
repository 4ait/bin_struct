defmodule BinStruct.Macro.TypeConverters.ModuleTypeConverter do


  def from_managed_to_unmanaged_module( { :module, _module_info }, quoted) do
    quoted
  end


  def from_unmanaged_to_managed_module({ :module, _module_info }, quoted) do
    quoted
  end

end