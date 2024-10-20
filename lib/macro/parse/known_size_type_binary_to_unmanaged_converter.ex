defmodule BinStruct.Macro.Parse.KnownSizeTypeBinaryToUnmanagedConverter do

  def convert_known_size_type_binary_to_unmanaged(access_field, type, opts, context) do

    options_access = { :options, [], context }

    case type do

      {:enum, %{type: enum_representation_type} } -> convert_known_size_type_binary_to_unmanaged(access_field, enum_representation_type, opts, context)
      {:flags, %{type: flags_representation_type} } -> convert_known_size_type_binary_to_unmanaged(access_field, flags_representation_type, opts, context)

      {:module, %{module_full_name: module_full_name} } ->

        expr =
          quote do
            unquote(module_full_name).parse_exact_returning_options(unquote(access_field), unquote(options_access))
          end

        { :bin_struct_parse_exact_result, expr }

      {:asn1, _asn1_info } ->

        expr =
          quote do
            %{
              binary: unquote(access_field),
              asn1_data: nil
            }
          end

        { :asn1_encode_expr, expr }

      {:variant_of, variants} ->

        with_patterns =
          Enum.map(
            variants,
            fn variant ->

              {:module, %{ module: module } } = variant

              quote do
                { :no_match, _reason, not_enough_bytes_seen } <-

                  (
                    result =  unquote(module).parse_exact_returning_options(unquote(access_field), unquote(options_access))

                    case result do
                      { :ok, _variant, _options } = ok_result ->  ok_result
                      :not_enough_bytes -> { :no_match, :not_enough_bytes, _not_enough_bytes_seen = true }
                      { :wrong_data, _wrong_data } = wrong_data -> { :no_match, wrong_data, not_enough_bytes_seen }
                    end
                  )

              end
                
            end
          )

        expr =
          quote do

              not_enough_bytes_seen = false

              with unquote_splicing(with_patterns) do

                case not_enough_bytes_seen do
                  true -> :not_enough_bytes
                  false ->  { :wrong_data, unquote(access_field) }
                end

              end
              
          end
          
        { :bin_struct_parse_exact_result, expr }
        

      { :list_of, list_of_info } ->

        case list_of_info do

          %{
            type: :static,
            item_type: item_type,
            bounds: bounds
          } ->

            %{
              length: _length,
              count: _count,
              item_size: _item_size,
            } = bounds

            expr = convert_known_size_list_of_binary_to_unmanaged(bounds, access_field, item_type, opts, context)

            { :items_parse_result, expr }

        end

      {:static_value, %{value: value} } ->

        expr = 
          quote do
            unquote(value)
          end

        { :static_value, expr }

        
      _type -> nil

    end

  end


  defp convert_known_size_list_of_binary_to_unmanaged(bounds, access_field, item_type, opts, context) do

     %{
       length: _length,
       item_size: item_size,
       count: count
     } = bounds

    bind_item = { :item, [], __MODULE__ }
    options_access = { :options, [], context }

    case item_type do

      { :module, _module_info }  ->

        { :bin_struct_parse_exact_result, item_encode_expr } = convert_known_size_type_binary_to_unmanaged(bind_item, item_type, opts, context)

        quote do

          { "", chunks } =
            Enum.reduce(
              1..unquote(count),
              { unquote(access_field), [] },
              fn _index, { bin, chunks } ->

                <<chunk::unquote(item_size)-bytes, rest::binary>> = bin

                { rest, [ chunk | chunks ] }

              end
            )

          chunks = Enum.reverse(chunks)

          result =
            Enum.reduce_while(chunks, { :ok, [], unquote(options_access) }, fn item, { :ok, curr_items, curr_options } ->

              unquote(options_access) = curr_options

              case unquote(item_encode_expr) do

                { :ok, encoded_item, new_options } ->

                  new_items = [ encoded_item | curr_items ]

                  { :cont, { :ok, new_items, new_options } }

                bad_result -> { :halt, bad_result }

              end

            end)


          case result do
            { :ok, items, options } ->  { :ok, Enum.reverse(items), options }
            bad_result -> bad_result
          end

        end

      _ ->

        quote do

          items =
            for << unquote(bind_item)::bytes-(unquote(item_size)) <- unquote(access_field) >> do

              unquote(
                convert_known_size_type_binary_to_unmanaged(bind_item, item_type, opts, context) || bind_item
              )

            end

          { :ok, items, unquote(options_access) }

        end

    end


  end

end