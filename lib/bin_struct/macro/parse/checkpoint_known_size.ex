defmodule BinStruct.Macro.Parse.CheckpointKnownSize do

  @moduledoc false

  alias BinStruct.Macro.AllFieldsSize
  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Parse.Validation
  alias BinStruct.Macro.Parse.Result
  alias BinStruct.Macro.Parse.BinaryMatchPatternKnownSize
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Dependencies.DeconstructionOfOnOptionDependencies
  alias BinStruct.Macro.Parse.KnownSizeTypeBinaryToUnmanagedConverter
  
  alias BinStruct.Macro.Dependencies.ParseDependencies
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies

  def checkpoint_known_size(fields = _checkpoint, function_name, registered_callbacks_map, _env) do

    dependencies = ParseDependencies.parse_dependencies_excluded_self(fields, registered_callbacks_map)
    dependencies_bindings = BindingsToOnFieldDependencies.bindings(dependencies, __MODULE__)

    fields_from_binary_to_unmanaged_conversion =
      Enum.map(
        fields,
        fn field ->

          case field do
            %Field{} = field ->

              %Field{ name: name, type: type, opts: opts } = field

              binary_access_bind = Bind.bind_binary_value(name, __MODULE__)

              parsed_unmanaged_type =
                KnownSizeTypeBinaryToUnmanagedConverter
                  .convert_known_size_type_binary_to_unmanaged(binary_access_bind, type, opts, __MODULE__)

              { field, parsed_unmanaged_type }

          end

        end
      )

    static_values_bindings =
      Enum.map(
        fields_from_binary_to_unmanaged_conversion,
        fn field_conversion ->

          { field, conversion } = field_conversion

          case conversion do

            {:static_value, static_value_expr } ->

              %Field{ name: name } = field

              unmanaged_value_bind = Bind.bind_unmanaged_value(name, __MODULE__)

              quote do
                unquote(unmanaged_value_bind) = unquote(static_value_expr)
              end

            _ -> nil

          end

        end
      ) |> Enum.reject(&is_nil/1)


    simple_reassign_binary_value_to_unmanaged =
      Enum.map(
        fields_from_binary_to_unmanaged_conversion,
        fn field_conversion ->

          { field, conversion } = field_conversion

          case conversion do

            nil ->

              %Field{ name: name } = field

              binary_access_bind = Bind.bind_binary_value(name, __MODULE__)
              unmanaged_value_bind = Bind.bind_unmanaged_value(name, __MODULE__)

              quote do
                unquote(unmanaged_value_bind) = unquote(binary_access_bind)
              end

            _ -> nil

          end

        end
      ) |> Enum.reject(&is_nil/1)


    structs_parse_with_clauses =
      Enum.map(
        fields_from_binary_to_unmanaged_conversion,
        fn field_conversion ->

          { field, conversion } = field_conversion

          %Field{ name: name } = field

          unmanaged_value_access = Bind.bind_unmanaged_value(name, __MODULE__)

          case conversion do

            { :failable_expr_result, encode_expr } ->

              quote do
                { :ok, unquote(unmanaged_value_access) } <- unquote(encode_expr)
              end

            { :module_parse_exact_result, encode_expr } ->

              quote do
                { :ok, unquote(unmanaged_value_access), options } <- unquote(encode_expr)
              end

            { :items_parse_result, encode_expr } ->

              quote do
                { :ok, unquote(unmanaged_value_access), options } <- unquote(encode_expr)
              end

            _ -> nil

          end

        end
      ) |> Enum.reject(&is_nil/1)


    binary_match_patterns =
      Enum.map(
        fields,
        fn field -> BinaryMatchPatternKnownSize.binary_match_pattern_for_known_size_field(field, __MODULE__) end
      )

    binary_match_patterns =
      binary_match_patterns ++ [
        quote do
          rest::binary
        end
      ]

    return_ok_clause = Result.return_ok_tuple(fields, __MODULE__)

    wrong_data_binary_bind = { :binary_for_wrong_data, [], __MODULE__ }

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude(fields, registered_callbacks_map, wrong_data_binary_bind, __MODULE__)

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


    size = AllFieldsSize.get_all_fields_size_bytes(fields)

    not_enough_bytes_clause =
      quote do

        defp unquote(function_name)(
               bin,
               unquote_splicing(dependencies_bindings),
               _options
             ) when is_binary(bin) and byte_size(bin) < unquote(size) do
          :not_enough_bytes
        end

      end

    wrong_data_clause =
      quote do

        defp unquote(function_name)(
               bin,
               unquote_splicing(dependencies_bindings),
               _options
             ) do
          { :wrong_data, bin }
        end

      end

    main_clause =
      quote do
        defp unquote(function_name)(
               <<unquote_splicing(binary_match_patterns)>> = bin,
               unquote_splicing(dependencies_bindings),
               options
             ) do

          unquote(
            DeconstructionOfOnOptionDependencies.option_dependencies_deconstruction(dependencies, __MODULE__)
          )

          unquote_splicing(static_values_bindings)
          unquote_splicing(simple_reassign_binary_value_to_unmanaged)

          unquote(wrong_data_binary_bind) = bin

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