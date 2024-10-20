defmodule BinStruct.Macro.Preprocess.RemapType do

  alias BinStruct.Macro.Preprocess.RemapListOf
  alias BinStruct.Macro.Preprocess.RemapAsn1
  alias BinStruct.Macro.Preprocess.RemapEnum
  alias BinStruct.Macro.Preprocess.RemapFlags
  alias BinStruct.Macro.Preprocess.RemapModule

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

        module when is_module -> RemapModule.remap_module(module, opts, nil, env)

        { :enum, _enum_info } = enum ->  RemapEnum.remap_enum(enum, opts, env)
        { :flags, _flags_info } = flags ->  RemapFlags.remap_flags(flags, opts, env)

        { :asn1, _asn1_info_ast } = asn1 ->  RemapAsn1.remap_asn1(asn1, opts, env)
        { :list_of, _item_type } = list_of ->  RemapListOf.remap_list_of(list_of, opts, env)

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

        static_value when is_static_value -> remap_static_value(static_value, opts, env)

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


  defp remap_static_value(static_value, opts, env) do


      case static_value do

        static_value when is_binary(static_value) or is_bitstring(static_value) ->

          value = escape_static_value(static_value)
          size_bits = bit_size(static_value)

          {
            :static_value,
            %{
              value: value,
              size_bits: size_bits
            }
          }

        bin_struct when is_struct(bin_struct) ->

          module = bin_struct.__struct__

          bin_struct_binary_dump = module.dump_binary(bin_struct)
          size_bits = bit_size(bin_struct_binary_dump)

          {
            :static_value,
            %{
              bin_struct: bin_struct,
              value: bin_struct_binary_dump,
              size_bits: size_bits
            }
          }

        { {:., _, [{:__aliases__, _, [:BinStructStaticValue]}, static_value_function]},_, static_value_function_arguments} ->

          expr =
            quote do
              unquote(:"Elixir.BinStructStaticValue").unquote(static_value_function)(unquote_splicing(static_value_function_arguments))
            end

          { value, _ } = Code.eval_quoted(expr, [], env)

          remap_static_value(value, opts, env)

        {:@, _meta, _value} = constant_ast ->

          { value, _ } = Code.eval_quoted(constant_ast, [], env)
          remap_static_value(value, opts, env)

        {:<<>>, _meta, _value} = bitstring_ast ->

          { value, _ } = Code.eval_quoted(bitstring_ast, [], env)
          remap_static_value(value, opts, env)

        {:fn, _meta, _value } = function ->

          static_value = call_function_and_get_value(function, env)
          remap_static_value(static_value, opts, env)

        {:&, _meta, _value } = function ->

          static_value = call_function_and_get_value(function, env)
          remap_static_value(static_value, opts, env)

      end

  end

  defp call_function_and_get_value(function, env) do

    function_call =
      quote do
        (unquote(function)).()
      end

    { value, _ } = Code.eval_quoted(function_call, [], env)

    value

  end

  defp is_static_value({{:., _, [{:__aliases__, _, [:BinStructStaticValue]}, _static_value_function]}, _, _static_value_function_arguments}), do: true
  defp is_static_value({:<<>>, _meta, _modules}), do: true
  defp is_static_value({:fn, _meta, _modules}), do: true
  defp is_static_value({:@, _meta, _modules}), do: true
  defp is_static_value({:&, _meta, _modules}), do: true
  defp is_static_value({value, _meta, _modules}) when is_binary(value), do: true
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


  defp escape_static_value(static_value) do

    escaped = Macro.escape(static_value)

    case escaped do

      static_value when is_binary(static_value) -> static_value

      {:<<>>, _meta, [pattern, {:"::", [], ["", {:binary, [], nil}]} ]} ->  { :<<>>, [], [pattern] }
      {:<<>>, _meta, _children } = bitstring ->  bitstring

    end

  end

end