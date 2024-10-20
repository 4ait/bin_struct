defmodule BinStruct.Macro.Preprocess.RemapModule do

  alias BinStruct.Macro.Preprocess.RemapCustomTypeArgs

  def remap_module(module, opts, env) do

    module_full_name = Macro.expand(module, env)

    module_type = apply(module_full_name, :__module_type__, [])

    case module_type do
      :bin_struct -> remap_bin_struct(module, module_full_name, opts, env)
      :bin_struct_custom_type -> remap_bin_struct_custom_type(module, module_full_name, opts, env)
    end

  end

  defp remap_bin_struct(module, module_full_name, _opts, _env) do


    size = apply(module_full_name, :known_total_size_bytes, [])

    {
      :module,
      %{
        module: module,
        module_full_name: module_full_name,
        module_type: :bin_struct,
        known_total_size_bytes: size
      }
    }

  end

  defp remap_bin_struct_custom_type(module, module_full_name, opts, env) do

    custom_type_args =
      RemapCustomTypeArgs.remap_custom_type_args(
        opts[:custom_type_args],
        env
      )

    size = apply(module_full_name, :known_total_size_bytes, [ custom_type_args ])

    {
      :module,
      %{
        module: module,
        module_full_name: module_full_name,
        module_type: :bin_struct_custom_type,
        custom_type_args: custom_type_args,
        known_total_size_bytes: size
      }
    }

  end

end