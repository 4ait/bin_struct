defmodule BinStruct.Macro.TypeConverters.ModuleTypeConverter do

  def from_managed_to_unmanaged_module( { :module, module_info }, quoted) do

    case module_info do

      %{ module_type: :bin_struct } -> quoted

      %{
        module_type: :bin_struct_custom_type,
        module: module,
        custom_type_args: custom_type_args
      } ->

      quote do
        unquote(module).to_unmanaged(unquote(quoted), unquote(custom_type_args))
      end

    end

  end


  def from_unmanaged_to_managed_module({ :module, module_info }, quoted) do

    case module_info do

      %{ module_type: :bin_struct } -> quoted

      %{
        module_type: :bin_struct_custom_type,
        module: module,
        custom_type_args: custom_type_args
      } ->

        quote do
          unquote(module).to_managed(unquote(quoted), unquote(custom_type_args))
        end

    end

  end

  def from_unmanaged_to_binary_module({ :module, module_info }, quoted) do

    case module_info do

      %{ module_type: :bin_struct, module: module } ->

        quote do
          unquote(module).dump_binary(unquote(quoted))
        end

      %{
        module_type: :bin_struct_custom_type,
        module: module,
        custom_type_args: custom_type_args
      } ->

        quote do
          unquote(module).dump_binary(unquote(quoted), custom_type_args)
        end

    end

  end

end