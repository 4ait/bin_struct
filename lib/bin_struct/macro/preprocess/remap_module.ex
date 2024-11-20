defmodule BinStruct.Macro.Preprocess.RemapModule do

  @moduledoc false

  alias BinStruct.Macro.Preprocess.RemapCustomTypeArgs

  def remap_module(module, _opts, custom_type_args, env) do

    module_full_name = Macro.expand(module, env)

    module_type = apply(module_full_name, :__module_type__, [])

    case module_type do
      :bin_struct -> remap_bin_struct(module, module_full_name, env)
      :bin_struct_custom_type -> remap_bin_struct_custom_type(module, module_full_name, custom_type_args, env)
    end

  end

  defp remap_bin_struct(module, module_full_name, _env) do

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


  defp remap_bin_struct_custom_type(module, module_full_name, custom_type_args, env) do

    custom_type_args =
      RemapCustomTypeArgs.remap_custom_type_args(
        custom_type_args,
        env
      )

    custom_type_args =
      case custom_type_args do
        nil -> nil
        custom_type_args ->

          { init_args_result, _binding} =
            Code.eval_quoted(
              quote do
                unquote(module_full_name).init_args(unquote(custom_type_args))
              end,
              [],
              env
            )

          case init_args_result do
            { :ok, custom_type_args } -> custom_type_args
            { :error, error } -> raise "Custom type #{module_full_name} args validation failed with error #{error}"
          end

      end


    size = apply(module_full_name, :known_total_size_bytes, [ custom_type_args ])

    {
      :module,
      %{
        module: module,
        module_full_name: module_full_name,
        module_type: :bin_struct_custom_type,
        custom_type_args: Macro.escape(custom_type_args),
        known_total_size_bytes: size
      }
    }

  end

end