defmodule BinStruct.Macro.Parse.OneOfPackMatchingClause do

  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Common
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.OneOfPack
  alias BinStruct.Macro.OneOfPackName
  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Parse.KnownSizeTypeEncoder

  def returning_tuple_with_bindings(%OneOfPack{} = one_of_pack, context) do

    %OneOfPack{ fields: one_of_pack_fields } = one_of_pack

    tuple_values =
      Enum.map(
        one_of_pack_fields,
        fn %Field{} = one_of_pack_field ->

          %Field{name: one_of_pack_field_name } = one_of_pack_field

          { Bind.bind_value_name(one_of_pack_field_name), [], context }
        end
      )

    quote do
      { unquote_splicing(tuple_values) }
    end

  end

  defp encode_exp_for_pack_value(pack_value_binding, type, opts, context) do

      case KnownSizeTypeEncoder.encode_known_size_type(pack_value_binding, type, opts, context) do
        { :static_value, static_value_expr } -> static_value_expr
        { :bin_struct_parse_exact_result, _result_expr } -> raise "bin_struct as part of one of not implemented"
        { :asn1_parse_result, _result_expr } -> raise "asn1 as part of one of not implemented"
        nil -> pack_value_binding
      end

  end

  def one_of_pack_matching_clause(%OneOfPack{} = one_of_pack, registered_callbacks_map, context) do

    %OneOfPack{ fields: one_of_pack_fields } = one_of_pack

    pack_name = OneOfPackName.one_of_pack_name(one_of_pack)
    pack_value_binding = { Bind.bind_value_name(pack_name), [], context }

    one_of_pack_case_patterns =
      Enum.map(
        one_of_pack_fields,
        fn %Field{} = one_of_pack_field ->

          %Field{type: type, opts: opts} = one_of_pack_field

          one_of_by = opts[:one_of_by]

          case one_of_by do

            one_of_by when not is_nil(one_of_by) ->

              registered_callback =
                RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, one_of_by)

              registered_callback_function_call =
                RegisteredCallbackFunctionCall.registered_callback_function_call(registered_callback, context)

              encode_expr = encode_exp_for_pack_value(pack_value_binding, type, opts, context)

              returning_tuple = get_returning_tuple(one_of_pack, one_of_pack_field, encode_expr)

              left = registered_callback_function_call

              right =
                quote do



                  unquote(returning_tuple)
                end

              Common.case_pattern(
                left,
                right
              )

            nil = _one_of_by when is_nil(one_of_by) ->

              encode_expr = encode_exp_for_pack_value(pack_value_binding, type, opts, context)
              returning_tuple = get_returning_tuple(one_of_pack, one_of_pack_field, encode_expr)

              left = true
              right = returning_tuple

              Common.case_pattern(
                left,
                right
              )

          end


        end
      )

    quote do

      cond do
        unquote(one_of_pack_case_patterns)
      end
    end

  end

  defp get_returning_tuple(%OneOfPack{} = one_of_pack, %Field{} = returning_field, returning_value_expr) do

    %OneOfPack{ fields: one_of_pack_fields } = one_of_pack

    tuple_values =
      Enum.map(
        one_of_pack_fields,
        fn %Field{} = one_of_pack_field ->

          case one_of_pack_field do
            ^returning_field ->

              returning_value_expr
            _ -> nil
          end

        end
      )

    quote do
      { unquote_splicing(tuple_values) }
    end

  end


end