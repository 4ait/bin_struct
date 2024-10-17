defmodule BinStruct.Macro.Parse.CheckpointKnownSize do

  alias BinStruct.Macro.AllFieldsSize
  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Parse.Validation
  alias BinStruct.Macro.Parse.Result
  alias BinStruct.Macro.Parse.BinaryMatchPatternKnownSize
  alias BinStruct.Macro.Parse.KnownSizeTypeEncoder
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.OneOfPack
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Parse.OneOfPackMatchingClause
  alias BinStruct.Macro.Parse.DeconstructOptionsForField
  alias BinStruct.Macro.Parse.ExternalFieldDependencies

  def checkpoint_known_size(fields_or_packs = _checkpoint, function_name, interface_implementations, registered_callbacks_map, _env) do

    fields = BinStruct.Macro.ExpandOneOfPacksFields.expand_one_of_packs_fields(fields_or_packs)

    external_field_dependencies = ExternalFieldDependencies.external_field_dependencies(fields, interface_implementations, registered_callbacks_map)

    value_arguments_binds =
      Enum.map(
        external_field_dependencies,
        fn argument ->

          case argument do
            %RegisteredCallbackFieldArgument{ field: %Field{ name: name } } ->
              { Bind.bind_value_name(name), [], __MODULE__ }

          end

        end
      )

    one_of_packs_fields_values =
      Enum.map(
        fields_or_packs,
        fn field_or_pack ->

          case field_or_pack do
            %Field{} -> nil
            %OneOfPack{} = pack ->

              matching_clause = OneOfPackMatchingClause.one_of_pack_matching_clause(pack, registered_callbacks_map, __MODULE__)
              returning_tuple = OneOfPackMatchingClause.returning_tuple_with_bindings(pack, __MODULE__)

              quote do
                unquote(returning_tuple) = unquote(matching_clause)
              end

          end

        end
      )
      |> Enum.reject(&is_nil/1)
      |> List.flatten()


    fields_encoding =
      Enum.map(
        fields_or_packs,
        fn field_or_pack ->

          case field_or_pack do
            %Field{} = field ->

              %Field{ name: name, type: type, opts: opts } = field

              access_field = { Bind.bind_value_name(name), [], __MODULE__ }

              encoding = KnownSizeTypeEncoder.encode_known_size_type(access_field, type, opts, __MODULE__)

              case encoding do
                nil -> nil
                encoding -> { field, encoding }
              end


            #pack values should be encoded separately
            %OneOfPack{} = _one_of_pack -> nil

          end

        end
      ) |> Enum.reject(&is_nil/1)

    static_values_bindings =
      Enum.map(
        fields_encoding,
        fn field_encoding ->

          { field, encoding } = field_encoding

          case encoding do
            {:static_value, static_value_expr } ->

              %Field{ name: name } = field

              access_field = { Bind.bind_value_name(name), [], __MODULE__ }

              quote do
                unquote(access_field) = unquote(static_value_expr)
              end

            _ -> nil
          end

        end
      ) |> Enum.reject(&is_nil/1)


    structs_parse_with_clauses =
      Enum.map(
        fields_encoding,
        fn field_encoding ->

          { field, encoding } = field_encoding

          %Field{ name: name } = field

          access_field = { Bind.bind_value_name(name), [], __MODULE__ }

          case encoding do

            { :bin_struct_parse_exact_result, encode_expr } ->

              quote do
                { :ok, unquote(access_field), options } <- unquote(encode_expr)
              end

            { :asn1_parse_result, asn1_encode_expr } -> asn1_encode_expr

            { :items_parse_result, encode_expr } ->

              quote do
                { :ok, unquote(access_field), options } <- unquote(encode_expr)
              end

            _ -> nil

          end

        end
      ) |> Enum.reject(&is_nil/1)


    binary_match_patterns =
      Enum.map(
        fields_or_packs,
        fn field_or_pack -> BinaryMatchPatternKnownSize.binary_match_pattern_for_known_size_field_or_pack(field_or_pack, __MODULE__) end
      )

    binary_match_patterns =
      binary_match_patterns ++ [
        quote do
          rest::binary
        end
      ]

    return_ok_clause = Result.return_ok_tuple(fields, __MODULE__)

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude(fields, registered_callbacks_map, __MODULE__)

    validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, return_ok_clause, __MODULE__)

    returning_clause =
      case structs_parse_with_clauses do
        [] ->  validate_and_return_clause

        structs_parse_with_clauses ->

          quote do

            with unquote_splicing(structs_parse_with_clauses) do

              unquote(validate_and_return_clause)

            end

          end

      end


    size = AllFieldsSize.get_all_fields_and_packs_size_bytes(fields_or_packs)

    not_enough_bytes_clause =
      quote do

        defp unquote(function_name)(
               bin,
               unquote_splicing(value_arguments_binds),
               _options
             ) when is_binary(bin) and byte_size(bin) < unquote(size) do
          :not_enough_bytes
        end

      end

    wrong_data_clause =
      quote do

        defp unquote(function_name)(
               bin,
               unquote_splicing(value_arguments_binds),
               _options
             ) do
          { :wrong_data, bin }
        end

      end

    main_clause =
      quote do
        defp unquote(function_name)(
               <<unquote_splicing(binary_match_patterns)>>,
               unquote_splicing(value_arguments_binds),
               options
             ) do

          unquote(DeconstructOptionsForField.deconstruct_options_for_fields(fields, interface_implementations, registered_callbacks_map, __MODULE__))

          unquote_splicing(one_of_packs_fields_values)
          unquote_splicing(static_values_bindings)

          unquote(returning_clause)

        end
      end

    [
      not_enough_bytes_clause,
      main_clause,
      wrong_data_clause
    ]

  end


  



end