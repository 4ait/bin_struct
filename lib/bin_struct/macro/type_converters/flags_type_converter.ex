defmodule BinStruct.Macro.TypeConverters.FlagsTypeConverter do

  @moduledoc false

  def from_managed_to_unmanaged_flags( { :flags, flags_info }, quoted) do

    #quoted is array of atom names and we should produce binary

    %{
      type: flags_representation_type,
      flags: flags,
      fallback_flag: fallback_flag
    } = flags_info

    flags_count = flags_count(flags_representation_type)
    endianness = flags_endianness(flags_representation_type)

    flag_info_by_flag_bit_position =
      Enum.map(
        flags,
        fn flag_info ->

          %{
            bit_position: bit_position
          } = flag_info


          { bit_position, flag_info }

        end
      ) |> Enum.into(%{})

    
    sent_bind = { :set, [], __MODULE__ }  
    
    flags_initialization = 
      Enum.map(
        1..flags_count,
        fn flag_index ->

          flag_info = Map.get(flag_info_by_flag_bit_position, flag_index)

          case flag_info do

            nil -> create_flag_zero_constructor(flag_index, __MODULE__)

            flag_info ->

              %{
                flag_name: flag_name
              } = flag_info

              create_flag_from_set_constructor(flag_index, flag_name, sent_bind, __MODULE__)

          end

        end
      )

    flags_construction =
      case endianness do

        :none ->

          quote do
            <<unquote_splicing(create_flags_binary_patterns(flags_count, __MODULE__))>>
          end

        :big ->

          quote do
            <<unquote_splicing(create_flags_binary_patterns(flags_count, __MODULE__))>>
          end

        :little ->

          quote do
            <<unquote_splicing(create_flags_binary_patterns(flags_count, __MODULE__) |> reverse_octets())>>
          end

      end


    flags_construction_body =

      quote do

        unquote(sent_bind) = :sets.from_list(value)

        unquote_splicing(flags_initialization)

        unquote(flags_construction)

      end

    flags_construction_with_fallback_check =

      case fallback_flag do

        nil -> flags_construction_body

        fallback_flag ->

          quote do

            case value do
              [] -> <<0::unquote(flags_count)>>
              [ unquote(fallback_flag) ] -> <<0::unquote(flags_count)>>
              value -> unquote(flags_construction_body)
            end

          end

      end
      
    quote do

      value = unquote(quoted)

      unquote(flags_construction_with_fallback_check)

    end



  end


  def from_unmanaged_to_managed_flags( { :flags, flags_info }, quoted) do

    %{
      type: flags_representation_type,
      flags: flags,
      fallback_flag: fallback_flag
    } = flags_info

    flags_count = flags_count(flags_representation_type)
    endianness = flags_endianness(flags_representation_type)

    flags_deconstruction =
      case endianness do

        :none ->

          quote do
            <<unquote_splicing(create_flags_binary_patterns(flags_count, __MODULE__) )>> = value
          end

        :big ->

          quote do
            <<unquote_splicing(create_flags_binary_patterns(flags_count, __MODULE__) )>> = value
          end

        :little ->

          quote do
            <<unquote_splicing(create_flags_binary_patterns(flags_count, __MODULE__) |> reverse_octets())>> = value
          end

      end

    flags_elements_access =
      Enum.map(
        flags,
        fn flag_info ->

          %{
            bit_position: bit_position,
            flag_name: flag_name
          } = flag_info

          quote do
            { unquote(flag_bind(bit_position, __MODULE__)), unquote(flag_name) }
          end

        end
      )

    flags_parse_body =

      quote do

        unquote(flags_deconstruction)

        flags_elements_access = unquote(flags_elements_access)

        Enum.filter(
          flags_elements_access,
          fn
            { 1, _flag_name } -> true
            { 0, _flag_name } -> false
          end
        )
        |> Enum.map(fn { _value, flag_name } -> flag_name end)

      end

    flags_parse_with_fallback_check =

      case fallback_flag do

        nil -> flags_parse_body

        fallback_flag ->

          quote do

            case value do
              <<0::unquote(flags_count)>> -> [ unquote(fallback_flag) ]
              value -> unquote(flags_parse_body)
            end

          end

      end

    quote do

      value = unquote(quoted)

      unquote(flags_parse_with_fallback_check)

    end

  end

  def from_unmanaged_to_binary_flags({ :flags, _flags_info }, quoted), do: quoted

  defp flag_bind(index, context) do
    {  :"f_#{index}", [], context  }
  end


  defp create_flags_binary_patterns(count, context) do

    Enum.map(
      1..count,
      fn index ->

        quote do
          unquote(flag_bind(index, context))::1
        end

      end
    )
    |> Enum.reverse()

  end

  defp create_flag_zero_constructor(flag_index, context) do

    quote do
      unquote(flag_bind(flag_index, context)) = 0
    end

  end

  defp create_flag_from_set_constructor(flag_index, flag_name, set_access, context) do

   quote do
     unquote(flag_bind(flag_index, context)) = (case :sets.is_element(unquote(flag_name), unquote(set_access)) do
       true -> 1
       false -> 0
     end)
   end

  end



  defp flags_count(flags_representation_type) do

    case flags_representation_type do
      :uint8 -> 8
      :uint16_be -> 16
      :uint16_le -> 16
      :uint32_be -> 32
      :uint32_le -> 32
      { :uint, %{ bit_size: bit_size } } -> bit_size
      { :int, %{ bit_size: bit_size } } -> bit_size
    end

  end

  defp flags_endianness(flags_representation_type) do

    case flags_representation_type do
      :uint8 -> :big
      :uint16_be -> :big
      :uint16_le -> :little
      :uint32_be -> :big
      :uint32_le -> :little
      { :uint, %{ endianness: endianness } } -> endianness
      { :int, %{ endianness: endianness } } -> endianness
    end

  end

  defp reverse_octets(list) do

    list
    |> Enum.reverse() #we will split from end
    |> Enum.chunk_every(8) #splitting
    |> Enum.map( fn chunk -> Enum.reverse(chunk) end  )
    |> List.flatten()

  end



end