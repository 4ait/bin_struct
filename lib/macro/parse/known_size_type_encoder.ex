defmodule BinStruct.Macro.Parse.KnownSizeTypeEncoder do


  alias BinStruct.Macro.Parse.KnownSizeListOfStaticEncoder
  alias BinStruct.Macro.Parse.KnownSizeListOfDynamicEncoder

  defp encode_known_size_list_of_expr(%{
    length: _length,
    item_size: _item_size,
    count: count
  } = bounds, access_field, item_type, opts, context )  do

    if count <= 32 do
      KnownSizeListOfStaticEncoder
        .encode_known_size_list_of_as_static_expr(bounds, access_field, item_type, opts, context)
    else

      KnownSizeListOfDynamicEncoder
        .encode_known_size_list_of_as_dynamic_expr(
          bounds, access_field, item_type, opts, context
        )

    end

  end

  def encode_known_size_type(access_field, type, opts, context) do

    options_access = { :options, [], context }

    case type do

      {:enum, %{type: enum_representation_type} } -> encode_known_size_type(access_field, enum_representation_type, opts, context)
      {:flags, %{type: flags_representation_type} } -> encode_known_size_type(access_field, flags_representation_type, opts, context)

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

            expr = encode_known_size_list_of_expr(bounds, access_field, item_type, opts, context)

            { :simple_value, expr }

        end

      {:static_value, %{ bin_struct: bin_struct } } ->

        bin_struct_escaped = Macro.escape(bin_struct)

        expr =
          quote do
            unquote(bin_struct_escaped)
          end

        { :static_value, expr }

      {:static_value, %{value: value} } ->

        expr = 
          quote do
            unquote(value)
          end

        { :static_value, expr }

        
      _type -> nil

    end

  end

end