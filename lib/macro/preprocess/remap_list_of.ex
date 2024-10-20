defmodule BinStruct.Macro.Preprocess.RemapListOf do

  alias BinStruct.Macro.Preprocess.RemapType
  alias BinStruct.Macro.FieldSize
  alias BinStruct.Macro.Termination
  alias BinStruct.Macro.BitSizeConverter

  def remap_list_of({:list_of, item_type}, opts, env) do

    item_type = RemapType.remap_type(item_type, opts, env)


    supported_string = "supported list_of item types are all primitives, binaries and bin_structs"

    case item_type do
      { :variant_of, _variants } -> raise "variant_of list_item type not supported directly, you could wrap it with another struct \n#{supported_string}"
      { :enum, _variants } -> raise "enum list_item type not supported \n#{supported_string}"
      { :flags, _variants } -> raise "flags list_item type not supported \n#{supported_string}"
      { :list_of, _list_of } -> raise "list_of list_item type not supported\n#{supported_string}"
      _ -> :ok
    end

    list_of_info =
      #at least 2 known at compile time
      case compile_time_bounds(item_type, opts) do

        compile_time_bounds when is_map(compile_time_bounds) ->

          %{
            type: :static,
            item_type: item_type,
            bounds: compile_time_bounds
          }

        :unknown ->

          #at least 2 will be known at runtime
          case runtime_bounds(item_type, opts, env) do

            runtime_bounds when is_map(runtime_bounds) ->

              %{
                type: :runtime_bounded,
                item_type: item_type,
                bounds: runtime_bounds
              }

            #so there is maybe only one known parameter or nothing
            :unknown ->

              #if length parameter is present we will get terminated results
              #without other params we can only parse terminated structs this way

              case any_length(item_type, opts) do

                any_length when not is_nil(any_length) ->

                  case item_type do

                    { :module, module_info } ->

                      if Termination.is_child_bin_struct_terminated(module_info) do

                        %{
                          type: :variable,
                          item_type: item_type,
                          termination: :terminated,
                          take: :until_length_by_parse,
                          any_length: any_length
                        }

                      else
                        raise array_does_not_have_required_constraints_error_message()
                      end

                    _ ->  raise array_does_not_have_required_constraints_error_message()

                  end

                _any_length = nil ->

                  #if count parameter is present we still can get terminated results in case of bin_struct
                  #can't parse other cases still
                  case any_count(item_type, opts) do
                    any_count when not is_nil(any_count) ->

                      case item_type do

                        { :module, module_info } ->

                          if Termination.is_child_bin_struct_terminated(module_info) do

                            %{
                              type: :variable,
                              item_type: item_type,
                              termination: :terminated,
                              take: :until_count_by_parse,
                              any_count: any_count
                            }

                          else
                            raise array_does_not_have_required_constraints_error_message()
                          end

                        _ ->  raise array_does_not_have_required_constraints_error_message()

                      end

                    _any_count = nil ->

                      #only by item size we can get terminated results if take_while_by callback_specified
                      #can parse arbitrary types too
                      case any_item_size(item_type, opts) do

                        any_item_size when not is_nil(any_item_size) ->

                          take_while_by = opts[:take_while_by]

                          case take_while_by do

                            take_while_by when not is_nil(take_while_by) ->

                              %{
                                type: :variable,
                                item_type: item_type,
                                termination: :terminated,
                                take: :take_while_by_callback_by_item_size,
                                any_item_size: any_item_size,
                                take_while_by: take_while_by
                              }

                            _take_while_by = nil ->

                              %{
                                type: :variable,
                                item_type: item_type,
                                termination: :not_terminated,
                                take: :until_end_by_item_size,
                                any_item_size: any_item_size
                              }

                          end

                         #we dont know anything
                         #can parse only in case of terminated structs until end
                        _any_size = nil ->

                          take_while_by = opts[:take_while_by]

                          case take_while_by do

                            take_while_by when not is_nil(take_while_by) ->

                              case item_type do

                                { :module, _module_info } ->

                                  %{
                                    type: :variable,
                                    item_type: item_type,
                                    termination: :terminated,
                                    take: :take_while_by_callback_by_parse,
                                    take_while_by: take_while_by
                                  }

                                _ ->  raise array_does_not_have_required_constraints_error_message()

                              end

                            _take_while_by = nil ->

                              case item_type do

                                { :module, module_info } ->

                                  if Termination.is_child_module_terminated(module_info) do

                                    %{
                                      type: :variable,
                                      item_type: item_type,
                                      termination: :not_terminated,
                                      take: :until_end_by_parse
                                    }

                                  else
                                    raise array_does_not_have_required_constraints_error_message()
                                  end

                                _ ->  raise array_does_not_have_required_constraints_error_message()

                              end

                          end



                      end

                  end

              end

          end

      end


    { :list_of, list_of_info }

  end

  defp array_does_not_have_required_constraints_error_message() do
     "array does not have required constraints on its bounds"
  end

  defp compile_time_bounds(item_type, opts) do

    case {
      compile_time_length(item_type, opts),
      compile_time_count(item_type, opts),
      compile_time_item_size(item_type, opts)
    } do

      { compile_time_length, compile_time_count, compile_time_item_size }
        when
          is_integer(compile_time_length) and
          is_integer(compile_time_count) and
          is_integer(compile_time_item_size)
      ->

        if Integer.mod(compile_time_length, compile_time_count) != 0 do
          raise "list_of boundaries could not be computed for length (#{compile_time_length}) and count (#{compile_time_count})"
        end

        if Integer.mod(compile_time_length, compile_time_item_size) != 0 do
          raise "list_of boundaries could not be computed for length (#{compile_time_length}) and item size (#{compile_time_item_size})"
        end

        computed_count = Integer.floor_div(compile_time_length, compile_time_item_size)

        if computed_count != compile_time_count do
          raise "list_of boundaries invalid, provided length (#{compile_time_length}), item size (#{compile_time_item_size}) and count (#{compile_time_count}) not resulting in common boundaries"
        end

        %{
          length: compile_time_length,
          count: compile_time_count,
          item_size: compile_time_item_size
        }

      { :unknown, compile_time_count, compile_time_item_size }
        when
          is_integer(compile_time_count) and
          is_integer(compile_time_item_size)
        ->

          %{
            length: compile_time_count * compile_time_item_size,
            count: compile_time_count,
            item_size: compile_time_item_size
          }

      { compile_time_length, :unknown, compile_time_item_size }
        when
          is_integer(compile_time_length) and
          is_integer(compile_time_item_size)
        ->


          if Integer.mod(compile_time_length, compile_time_item_size) != 0 do
            raise "list_of boundaries could not be computed for length (#{compile_time_length}) and item size (#{compile_time_item_size})"
          end

          %{
            length: compile_time_length,
            count: Integer.floor_div(compile_time_length, compile_time_item_size),
            item_size: compile_time_item_size
          }

      { compile_time_length, compile_time_count, :unknown }
        when
          is_integer(compile_time_length) and
          is_integer(compile_time_count)
        ->

          if Integer.mod(compile_time_length, compile_time_count) != 0 do
            raise "list_of boundaries could not be computed for length (#{compile_time_length}) and count (#{compile_time_count})"
          end

          %{
            length: compile_time_length,
            count: compile_time_count,
            item_size: Integer.floor_div(compile_time_length, compile_time_count)
          }

       _ -> :unknown

    end
    
  end
  

  defp compile_time_length(_item_type, opts) do

    length = opts[:length]

    case length do
      length when not is_nil(length) -> length
      _length = nil -> :unknown
    end
    
  end

  defp compile_time_count(_item_type, opts) do

    count = opts[:count]

    case count do
      count when not is_nil(count) -> count
      _count = nil -> :unknown
    end

  end

  defp compile_time_item_size(item_type, opts) do

    item_size = opts[:item_size]

    case item_size do

      item_size when not is_nil(item_size) -> item_size

      nil ->

        known_item_size_bytes =
          FieldSize.type_size_bits(item_type, [])
          |> BitSizeConverter.bit_size_to_byte_size()

        case known_item_size_bytes do
          item_size when is_integer(item_size) -> item_size
          :unknown -> :unknown
        end


    end

  end


  defp any_length(item_type, opts) do

    case { compile_time_length(item_type, opts), runtime_length(item_type, opts) } do
      { compile_time, _runtime } when compile_time != :unknown -> { :compile_time, compile_time }
      { _compile_time, runtime } when runtime != :unknown -> { :runtime, runtime }
      _ -> nil
    end

  end

  defp any_count(item_type, opts) do

    case { compile_time_count(item_type, opts), runtime_count(item_type, opts) } do
      { compile_time, _runtime } when compile_time != :unknown -> { :compile_time, compile_time }
      { _compile_time, runtime } when runtime != :unknown -> { :runtime, runtime }
      _ -> nil
    end

  end

  defp any_item_size(item_type, opts) do

    case { compile_time_item_size(item_type, opts), runtime_item_size(item_type, opts) } do
      { compile_time, _runtime } when compile_time != :unknown -> { :compile_time, compile_time }
      { _compile_time, runtime } when runtime != :unknown -> { :runtime, runtime }
      _ -> nil
    end

  end

  defp runtime_bounds(item_type, opts, _env) do

    any_length = any_length(item_type, opts)
    any_count = any_count(item_type, opts)
    any_item_size = any_item_size(item_type, opts)

    case { any_length, any_count, any_item_size } do

      { any_length, any_count, any_item_size }
        when
          not is_nil(any_length) and
          not is_nil(any_count) and
          not is_nil(any_item_size)
        ->

          %{
            any_length: any_length,
            any_count: any_count,
            any_item_size: any_item_size
          }

      { _any_length, any_count, any_item_size }
        when
          not is_nil(any_count) and
          not is_nil(any_item_size)
        ->

          %{
            any_count: any_count,
            any_item_size: any_item_size
          }


      { any_length, _any_count, any_item_size }
        when
          not is_nil(any_length) and
          not is_nil(any_item_size)
        ->

          %{
            any_length: any_length,
            any_item_size: any_item_size
          }

      { any_length, any_count, _any_item_size }
        when
          not is_nil(any_length) and
          not is_nil(any_count)
        ->

          %{
            any_length: any_length,
            any_count: any_count
          }

      _ -> :unknown

    end

  end
  

  defp runtime_length(_item_type, opts) do

    length_by = opts[:length_by]

    case length_by do
      length_by when not is_nil(length_by) -> length_by
      _length_by = nil -> :unknown
    end

  end

  defp runtime_count(_item_type, opts) do

    count_by = opts[:count_by]

    case count_by do
      count_by when not is_nil(count_by) -> count_by
      _count_by = nil -> :unknown
    end

  end

  defp runtime_item_size(_item_type, opts) do

    item_size_by = opts[:item_size_by]

    case item_size_by do
      item_size_by when not is_nil(item_size_by) -> item_size_by
      _item_size_by = nil -> :unknown
    end

  end


end