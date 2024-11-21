defmodule BinStruct.Macro.Preprocess.RemapFlags do

  @moduledoc false

  alias BinStruct.Macro.Preprocess.RemapType

  def remap_flags({:flags, flags_info_ast}, opts, env) do

    {:%{}, _meta, [type: flags_representation_type, values: flags_values]} = flags_info_ast

    { flags_values, _binding } = Code.eval_quoted(flags_values, [], env)

    flags_representation_type = RemapType.remap_type(flags_representation_type, opts, env)

    values =
      Enum.map(
        flags_values,
        fn { flag_value, flag_name } ->

          case flag_value do

            0 ->

              %{
                fallback_flag: true,
                flag_name: flag_name
              }

            flag_value  ->

              bit_position = integer_to_bit_position(flag_value)

              %{
                bit_position: bit_position,
                flag_name: flag_name
              }

          end

        end
      )


    { fallback_flag, flags } = split_fallback_flag_and_flags(values)

    unique_bit_positions =
      flags
      |> Enum.uniq_by(fn value ->

        case value do
          %{ bit_position: bit_position } -> bit_position
        end

      end)

    total_flags_count =
      Enum.count(values) - (if fallback_flag, do: 1, else: 0)

    if Enum.count(unique_bit_positions) != total_flags_count do
      raise "Duplicate bit positions in values: #{inspect(values)}"
    end

    { :flags,
      %{
        type: flags_representation_type,
        flags: flags,
        fallback_flag: fallback_flag
      }
    }

  end

  defp integer_to_bit_position(value) do

    case value do
      0x01 -> 1
      0x02 -> 2
      0x04 -> 3
      0x08 -> 4
      0x10 -> 5
      0x20 -> 6
      0x40 -> 7
      0x80 -> 8
      0x100 -> 9
      0x200 -> 10
      0x400 -> 11
      0x800 -> 12
      0x1000 -> 13
      0x2000 -> 14
      0x4000 -> 15
      0x8000 -> 16
      0x10000 -> 17
      0x20000 -> 18
      0x40000 -> 19
      0x80000 -> 20
      0x100000 -> 21
      0x200000 -> 22
      0x400000 -> 23
      0x800000 -> 24
      0x1000000 -> 25
      0x2000000 -> 26
      0x4000000 -> 27
      0x8000000 -> 28
      0x10000000 -> 29
      0x20000000 -> 30
      0x40000000 -> 31
      0x80000000 -> 32
      0x100000000 -> 33
      0x200000000 -> 34
      0x400000000 -> 35
      0x800000000 -> 36
      0x1000000000 -> 37
      0x2000000000 -> 38
      0x4000000000 -> 39
      0x8000000000 -> 40
      0x10000000000 -> 41
      0x20000000000 -> 42
      0x40000000000 -> 43
      0x80000000000 -> 44
      0x100000000000 -> 45
      0x200000000000 -> 46
      0x400000000000 -> 47
      0x800000000000 -> 48
      0x1000000000000 -> 49
      0x2000000000000 -> 50
      0x4000000000000 -> 51
      0x8000000000000 -> 52
      0x10000000000000 -> 53
      0x20000000000000 -> 54
      0x40000000000000 -> 55
      0x80000000000000 -> 56
      0x100000000000000 -> 57
      0x200000000000000 -> 58
      0x400000000000000 -> 59
      0x800000000000000 -> 60
      0x1000000000000000 -> 61
      0x2000000000000000 -> 62
      0x4000000000000000 -> 63
      0x8000000000000000 -> 64
      _ -> raise "#{value} not a bit position"
    end

  end

  defp split_fallback_flag_and_flags(flags) do

    { fallback_flag, flags } =
      Enum.split_with(
        flags,
        fn flag ->

          case flag do
            %{ fallback_flag: true } -> true
            _flag -> false
          end
        end
      )

    fallback_flag =
      case fallback_flag do
        [] -> nil
        [ %{ flag_name: flag_name }] -> flag_name
      end

    { fallback_flag, flags }

  end

end