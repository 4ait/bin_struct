defmodule BinStruct.Macro.Preprocess.RemapFlags do

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

              flag_value when is_integer(flag_value) ->

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

              flag_value ->

                { :at, bit_position } = flag_value

                  case bit_position do

                    bit_position when bit_position < 1 ->  raise "#{bit_position} not a bit position"
                    bit_position when bit_position > 32 ->  raise "unsupported #{bit_position} bit position"

                    bit_position ->

                      %{
                        bit_position: bit_position,
                        flag_name: flag_name
                      }


                  end

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