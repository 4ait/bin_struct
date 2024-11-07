defmodule BinStruct.Macro.FieldSize do

  alias BinStruct.Macro.Structs.Field

  def field_size_bits(%Field{} = field) do

    %Field{ type: type, opts: opts } = field

    type_size_bits(type, opts)

  end

  def type_size_bits(type, opts) do

    length = opts[:length]
    length_by = opts[:length_by]


    case type do

      { :enum, %{ type: enum_representation_type } } -> type_size_bits(enum_representation_type, opts)
      { :flags, %{ type: flags_representation_type } } -> type_size_bits(flags_representation_type, opts)

      { :list_of, _item_type } = list_of -> list_of_size_bits(list_of, opts)

      _type when is_integer(length) -> length * 8
      _type when not is_nil(length_by) -> :unknown

      { :module, _module_info } = module -> module_size_bits(module, opts)
      { :variant_of, _variants } = variant_of -> variant_of_size_bits(variant_of, opts)

      {:static_value, %{size_bits: size_bits}} -> size_bits

      { :uint, %{ bit_size: bit_size } } -> bit_size
      { :int, %{ bit_size: bit_size } } -> bit_size

      { :bool, %{ bit_size: bit_size } } -> bit_size

      :uint8 -> 8
      :int8 -> 8

      :uint16_be -> 16
      :uint32_be -> 32
      :uint64_be -> 64
      :int16_be -> 16
      :int32_be -> 32
      :int64_be -> 64
      :float32_be -> 32
      :float64_be -> 64

      :uint16_le -> 16
      :uint32_le -> 32
      :uint64_le -> 64
      :int16_le -> 16
      :int32_le -> 32
      :int64_le -> 64
      :float32_le -> 32
      :float64_le -> 64

      :binary -> :unknown

      type -> raise "invalid #{inspect(type)} with options #{inspect(opts)}"

    end

  end


  defp list_of_size_bits({ :list_of, list_info }, _opts) do

    case list_info do
      %{ type: :static, bounds: bounds } ->

        %{length: length }  = bounds

        length * 8

      _ -> :unknown
    end

  end

  defp variant_of_size_bits({ :variant_of, variants }, opts) do

    Enum.reduce_while(
      variants,
      0,
      fn variant, acc ->

        variant_type_size_bits = type_size_bits(variant, opts)

        case variant_type_size_bits do

          variant_type_size_bits when is_integer(variant_type_size_bits) ->

            case acc do
              0 -> { :cont, variant_type_size_bits }
              acc when acc == variant_type_size_bits -> { :cont, variant_type_size_bits }
              _ -> {:halt, :unknown}
            end

          :unknown -> {:halt, :unknown}

        end

      end
    )

  end

  defp module_size_bits({ :module, module_info }, _opts) do

    case module_info do

      %{ known_total_size_bytes: known_total_size_bytes } when is_integer(known_total_size_bytes) ->
        known_total_size_bytes * 8

      %{} -> :unknown

    end

  end




end