defmodule BinStruct.Macro.Parse.KnownSizeTypeBinaryToUnmanagedConverter do

  alias BinStruct.Macro.Common

  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap

  @moduledoc false

  def convert_known_size_type_binary_to_unmanaged(binary_access_bind, type, opts, registered_callbacks_map, context) do

    options_access = { :options, [], context }

    case type do

      {:enum, %{ type: enum_representation_type, values: values } } ->

        enum_validation_case_patterns =
          Enum.map(
            values,
            fn %{} = enum_variant ->

              %{
                enum_value: enum_value
              } = enum_variant

              Common.case_pattern(

                enum_value,

                quote do
                  :exists
                end
              )

            end
          )


        enum_validation_case_patterns = enum_validation_case_patterns ++ [

            Common.case_pattern(
              quote do
                _
              end,
              quote do
                :not_exists
              end
            )

          ]

        representation_type_as_unmanaged =

          case convert_known_size_type_binary_to_unmanaged(binary_access_bind, enum_representation_type, opts, registered_callbacks_map,context) do
            nil -> binary_access_bind
            unmanaged -> unmanaged
          end

          representation_type_as_managed_expr =
             BinStruct.Macro.TypeConverterToManaged.convert_unmanaged_value_to_managed(enum_representation_type, representation_type_as_unmanaged)


          parse_expr =
            quote do

              validate_enum_variant_exists_result =
                case unquote(representation_type_as_managed_expr) do
                  unquote(enum_validation_case_patterns)
                end

              case validate_enum_variant_exists_result do
                :exists -> { :ok, unquote(representation_type_as_unmanaged) }
                :not_exists -> { :wrong_data, unquote(binary_access_bind) }
              end

          end

        { :failable_expr_result, parse_expr }


      {:flags, %{type: flags_representation_type} } -> convert_known_size_type_binary_to_unmanaged(binary_access_bind, flags_representation_type, opts, registered_callbacks_map, context)

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

        expr =
          case opts[:select_variant_by] do

            select_variant_by when not is_nil(select_variant_by) ->
              parse_variant_by_select_variant_by_callback(variants, binary_access_bind, options_access, select_variant_by, registered_callbacks_map, context)

            nil -> parse_variant_by_first_with_non_wrong_data(variants, binary_access_bind, options_access)

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

            expr = convert_known_size_list_of_binary_to_unmanaged(bounds, binary_access_bind, item_type, opts, registered_callbacks_map, context)

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


  defp convert_known_size_list_of_binary_to_unmanaged(bounds, binary_access_bind, item_type, opts, registered_callbacks_map, context) do

     %{
       length: _length,
       item_size: item_size,
       count: _count
     } = bounds

    bind_item = { :item, [], __MODULE__ }
    options_access = { :options, [], context }

    case item_type do

      { :module, _module_info }  ->

        { :module_parse_exact_result, item_encode_expr } = convert_known_size_type_binary_to_unmanaged(bind_item, item_type, opts, registered_callbacks_map, context)

        quote do

          chunks =
            for << chunk::binary-size(unquote(item_size)) <- unquote(binary_access_bind) >> do
              chunk
            end

          result =
            Enum.reduce_while(chunks, { :ok, [], unquote(options_access) }, fn item, { :ok, curr_items, curr_options } ->

              unquote(options_access) = curr_options

              case unquote(item_encode_expr) do

                { :ok, encoded_item, options } ->

                  new_items = [ encoded_item | curr_items ]

                  { :cont, { :ok, new_items, options } }

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
                convert_known_size_type_binary_to_unmanaged(bind_item, item_type, opts, registered_callbacks_map, context) || bind_item
              )

            end

          { :ok, items, unquote(options_access) }

        end

    end


  end


  defp parse_variant_by_select_variant_by_callback(variants, binary_access_bind, options_access, select_variant_by_callback, registered_callbacks_map, context) do

    select_variant_by_registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, select_variant_by_callback)

    quote do

      variant_by_call = unquote(
        RegisteredCallbackFunctionCall.registered_callback_function_call(
          select_variant_by_registered_callback,
          context
        )
      )

      case variant_by_call do

        unquote(

          Enum.map(
            variants,
            fn variant ->

              {:module, module_info } = variant

              case module_info do

                %{ module_type: :bin_struct, module: module } ->

                  bin_struct_parse_expr =
                    quote do
                      unquote(module).parse_exact_returning_options(unquote(binary_access_bind), unquote(options_access))
                    end


                  BinStruct.Macro.Common.case_pattern(module, bin_struct_parse_expr)

                %{
                  module_type: :bin_struct_custom_type,
                  module: module,
                  custom_type_args: custom_type_args
                } ->

                  bin_struct_custom_type_parse_expr =
                    quote do
                      unquote(module).parse_exact_returning_options(unquote(binary_access_bind), unquote(custom_type_args), unquote(options_access))
                    end

                  BinStruct.Macro.Common.case_pattern(module, bin_struct_custom_type_parse_expr)

              end
            end
          )
        )

      end

    end

  end

  defp parse_variant_by_first_with_non_wrong_data(variants, binary_access_bind, options_access) do

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

    quote do

      with unquote_splicing(with_patterns) do
        { :wrong_data, unquote(binary_access_bind) }
      end

    end

  end

end