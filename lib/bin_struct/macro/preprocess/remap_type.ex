defmodule BinStruct.Macro.Preprocess.RemapType do

  @moduledoc false

  alias BinStruct.Macro.Preprocess.RemapListOf
  alias BinStruct.Macro.Preprocess.RemapEnum
  alias BinStruct.Macro.Preprocess.RemapFlags
  alias BinStruct.Macro.Preprocess.RemapModule
  alias BinStruct.Macro.Preprocess.RemapStaticValue

  def remap_type(type, opts, env) do

      if opts[:termination] do
        raise "termination option support has been dropped, use TerminatedBinary custom type instead"
      end

      is_module =
        case type do
          { first_element, _second_element } -> is_module(first_element)
          single_declaration -> is_module(single_declaration)
        end

      is_static_value = is_static_value(type)

      bits = opts[:bits]

      case type do

        { module, custom_type_args } when is_module -> RemapModule.remap_module(module, opts, custom_type_args, env)

        { :unspecified, _type_spec } -> :unspecified

        module when is_module -> RemapModule.remap_module(module, opts, nil, env)

        { :enum, _enum_info } = enum -> RemapEnum.remap_enum(enum, opts, env)
        { :flags, _flags_info } = flags -> RemapFlags.remap_flags(flags, opts, env)

        { :list_of, _item_type } = list_of -> RemapListOf.remap_list_of(list_of, opts, env)

        { :variant_of, _variants } = variant_of -> remap_variant_of(variant_of, opts, env)

        :bool when not is_nil(bits) -> { :bool, %{ bit_size: bits } }
        :bool -> { :bool, %{ bit_size: 8 } }

        :uint when is_integer(bits) and bits < 9 -> { :uint, %{ bit_size: bits, endianness: :none } }

        :uint when is_integer(bits) and bits < 9 -> { :uint, %{ bit_size: bits, endianness: :none } }
        :int  when is_integer(bits) and bits < 9 -> { :int, %{ bit_size: bits, endianness: :none } }

        :uint_be when is_integer(bits) -> { :uint, %{ bit_size: bits, endianness: :big } }
        :uint_le when is_integer(bits) -> { :uint, %{ bit_size: bits, endianness: :little } }

        :int_be when is_integer(bits) -> { :int, %{ bit_size: bits, endianness: :big } }
        :int_le when is_integer(bits) -> { :int, %{ bit_size: bits, endianness: :little } }

        static_value when is_static_value -> RemapStaticValue.remap_static_value(static_value, opts, env)

        type -> type

      end

  end

  defp remap_variant_of({:variant_of, variants}, opts, env) do

    case are_all_variants_are_modules(variants) do
      :ok ->
        { :variant_of, Enum.map(variants, fn variant -> remap_type(variant, opts, env) end) }

      {:not_module, variant} ->
        raise "Only bin_struct's supported for :variant_of variant. Giving: #{inspect(variant)}"

    end

  end

  defp is_static_value(value) when is_binary(value), do: true
  defp is_static_value({:<<>>, _meta, _value}), do: true
  defp is_static_value({ :static, _ast }), do: true

  defp is_static_value(_), do: false


  defp is_module({:__aliases__, _meta, _modules}), do: true
  defp is_module(_), do: false


  defp are_all_variants_are_modules([]), do: :ok

  defp are_all_variants_are_modules([head | tail]) do

    if is_module(head) do
      are_all_variants_are_modules(tail)
    else
      { :not_module,  head}
    end

  end

end