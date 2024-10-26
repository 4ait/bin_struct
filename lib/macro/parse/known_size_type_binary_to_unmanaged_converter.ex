defmodule BinStruct.Macro.Parse.KnownSizeTypeBinaryToUnmanagedConverter do

  def convert_known_size_type_binary_to_unmanaged(binary_access_bind, type, opts, context) do

    options_access = { :options, [], context }

    case type do

      {:enum, %{type: enum_representation_type} } -> convert_known_size_type_binary_to_unmanaged(binary_access_bind, enum_representation_type, opts, context)
      {:flags, %{type: flags_representation_type} } -> convert_known_size_type_binary_to_unmanaged(binary_access_bind, flags_representation_type, opts, context)

      {:module, module_info } ->

        module_parse_expr =

          case module_info do

            %{ module_type: :bin_struct, module: module } ->

              quote do
                unquote(module).parse_exact_returning_options(unquote(binary_access_bind), unquote(options_access))
              end

            %{
              module_type: :bin_struct_custom_type,
              module: module,
              custom_type_args: custom_type_args
            } ->
              quote do
                unquote(module).parse_exact_returning_options(unquote(binary_access_bind), unquote(custom_type_args), unquote(options_access))
              end
          end

        { :module_parse_exact_result, module_parse_expr }

      {:variant_of, variants} ->

        with_patterns =
          Enum.map(
            variants,
            fn variant ->

              {:module, module_info } = variant

              module_parse_expr =
                case module_info do

                  %{ module_type: :bin_struct, module: module } ->

                    quote do
                      unquote(module).parse_exact_returning_options(unquote(binary_access_bind), unquote(options_access))
                    end

                  %{
                    module_type: :bin_struct_custom_type,
                    module: module,
                    custom_type_args: custom_type_args
                  } ->
                    quote do
                      unquote(module).parse_exact_returning_options(unquote(binary_access_bind), unquote(custom_type_args), unquote(options_access))
                    end
                end

              quote do
                { :no_match, _reason } <-

                  (
                    case unquote(module_parse_expr) do
                      { :ok, _variant, _options } = ok_result ->  ok_result
                      { :wrong_data, _wrong_data } = wrong_data -> { :no_match, wrong_data }
                    end
                  )

              end
                
            end
          )

        expr =
          quote do

              with unquote_splicing(with_patterns) do
                { :wrong_data, unquote(binary_access_bind) }
              end
              
          end
          
        { :module_parse_exact_result, expr }
        

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

            expr = convert_known_size_list_of_binary_to_unmanaged(bounds, binary_access_bind, item_type, opts, context)

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


  defp convert_known_size_list_of_binary_to_unmanaged(bounds, binary_access_bind, item_type, opts, context) do

     %{
       length: _length,
       item_size: item_size,
       count: _count
     } = bounds

    bind_item = { :item, [], __MODULE__ }
    options_access = { :options, [], context }

    case item_type do

      { :module, _module_info }  ->

        { :module_parse_exact_result, item_encode_expr } = convert_known_size_type_binary_to_unmanaged(bind_item, item_type, opts, context)

        quote do

          chunks =
            for << chunk::binary-size(unquote(item_size)) <- unquote(binary_access_bind) >> do
              chunk
            end

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
            for << unquote(bind_item)::bytes-(unquote(item_size)) <- unquote(binary_access_bind) >> do

              unquote(
                convert_known_size_type_binary_to_unmanaged(bind_item, item_type, opts, context) || bind_item
              )

            end

          { :ok, items, unquote(options_access) }

        end

    end


  end

end