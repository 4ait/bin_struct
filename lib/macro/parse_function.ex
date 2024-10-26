defmodule BinStruct.Macro.ParseFunction do

  alias BinStruct.Macro.FieldSize
  alias BinStruct.Macro.Bind

  alias BinStruct.Macro.Parse.CheckpointKnownSize
  alias BinStruct.Macro.Parse.CheckpointOptionalByOfKnownSize
  alias BinStruct.Macro.Parse.CheckpointUnknownSize
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Parse.MaybeCallInterfaceImplementationCallbacksAndCollapseNewOptions
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionUnspecified
  alias BinStruct.TypeConversion.TypeConversionBinary
  alias BinStruct.Macro.Parse.TypeConverterCheckpointInputOutputByIndex

  alias BinStruct.Macro.Dependencies.IsFieldDependentOn
  alias BinStruct.Macro.TypeConverterToManaged
  alias BinStruct.Macro.TypeConverterToBinary
  
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies
  alias BinStruct.Macro.Dependencies.ParseDependencies

  #todo read calls in parse may not work

  def parse_function(fields, interface_implementations, registered_callbacks_map, env, is_should_be_defined_private) do

    parse_checkpoints = hydrate_parse_checkpoints([], fields, registered_callbacks_map)

    dependencies_per_checkpoint =
      Enum.map(
        parse_checkpoints,
        fn checkpoint ->
          ParseDependencies.parse_dependencies_excluded_self(checkpoint, registered_callbacks_map)
        end
      )

    type_converter_checkpoint_input_output_by_index =
      TypeConverterCheckpointInputOutputByIndex.type_converter_checkpoint_input_output_by_index(dependencies_per_checkpoint)


    parse_checkpoints_functions =
      Enum.map(
        Enum.with_index(parse_checkpoints, 1),
           fn {checkpoint, index} ->
             parse_checkpoint_function(
               checkpoint,
               index,
               registered_callbacks_map,
               env
             )
           end)
      |> List.flatten()

    type_conversion_checkpoints_functions =
      Enum.map(
        type_converter_checkpoint_input_output_by_index,
           fn {index, input, output} ->
             type_conversion_checkpoint_function(
               index,
               input,
               output
             )
           end)

    checkpoints_with_clauses =
      Enum.map(

        Enum.with_index(parse_checkpoints, 1),
        fn { fields, index } ->

          maybe_type_converter_checkpoint =
            Enum.find(
              type_converter_checkpoint_input_output_by_index,
              fn { type_converter_checkpoint_index, _input, _output } -> type_converter_checkpoint_index == index end
            )

          returning_from_checkpoint_values_binds =
            Enum.map(
              fields,
              fn %Field{} = field ->

                %Field{ name: name } = field

                Bind.bind_unmanaged_value(name, __MODULE__)

              end
            )

          maybe_type_conversion_clause_before =

            case maybe_type_converter_checkpoint do
              nil -> nil
              { _index, input_dependencies, output_dependencies } ->

                input_binds =
                  Enum.map(
                    input_dependencies,
                    fn input_dependency ->

                      case input_dependency do
                        %BinStruct.Macro.Structs.DependencyOnField{} = dependency ->

                          %BinStruct.Macro.Structs.DependencyOnField{
                            field: field
                          } = dependency

                          name =
                            case field do
                              %Field{ name: name } -> name
                              %VirtualField{ name: name } -> name
                            end

                          Bind.bind_unmanaged_value(name, __MODULE__)

                        %BinStruct.Macro.Structs.DependencyOnOption{} -> nil

                      end

                    end
                  ) |> Enum.reject(&is_nil/1)

                output_binds =
                  Enum.map(
                    output_dependencies,
                    fn output_dependency ->

                      case output_dependency do

                        %BinStruct.Macro.Structs.DependencyOnField{} = dependency ->

                          %BinStruct.Macro.Structs.DependencyOnField{
                            field: field,
                            type_conversion: type_conversion
                          } = dependency

                          name =
                            case field do
                              %Field{ name: name } -> name
                              %VirtualField{ name: name } -> name
                            end

                          case type_conversion do
                            TypeConversionUnspecified -> Bind.bind_managed_value(name, __MODULE__)
                            TypeConversionManaged -> Bind.bind_managed_value(name, __MODULE__)
                            TypeConversionUnmanaged -> Bind.bind_unmanaged_value(name, __MODULE__)
                            TypeConversionBinary-> Bind.bind_binary_value(name, __MODULE__)
                          end

                        %BinStruct.Macro.Structs.DependencyOnOption{} -> nil
                      end

                    end
                  ) |> Enum.reject(&is_nil/1)

                quote do
                  { unquote_splicing(output_binds) } <- unquote(type_conversion_checkpoint_function_name(index))(unquote_splicing(input_binds))
                end

            end

          binding_to_received_by_checkpoint_arguments =
            BindingsToOnFieldDependencies.bindings(
              ParseDependencies.parse_dependencies_excluded_self(fields, registered_callbacks_map), __MODULE__
            )

          parse_checkpoint_with_clause =
            quote do
              { :ok, unquote_splicing(returning_from_checkpoint_values_binds), rest, options } <-
                unquote(parse_checkpoint_function_name(index))(rest, unquote_splicing(binding_to_received_by_checkpoint_arguments), options)
            end

          Enum.reject([
            maybe_type_conversion_clause_before,
            parse_checkpoint_with_clause
          ], &is_nil/1)

        end
      ) |> List.flatten()

    returning_struct_key_values =
      Enum.map(
        parse_checkpoints,
        fn fields ->

          Enum.map(
            fields,
            fn %Field{} = field ->

               %Field{ name: name } = field

              { name, Bind.bind_unmanaged_value(name, __MODULE__) }

            end
          )

        end
      ) |> List.flatten()

    maybe_implemented_options_call =
      MaybeCallInterfaceImplementationCallbacksAndCollapseNewOptions.maybe_call_interface_implementations_callbacks(interface_implementations, registered_callbacks_map, __MODULE__)

    implemented_options_call =
        case maybe_implemented_options_call do

          nil -> []

          implemented_options_call ->
            expr =
              quote do
                options = unquote(implemented_options_call)
              end

            [expr]

        end

    parse_function_body =
      quote do

        options =
          case options do
            nil -> __default_options__()
            options when is_list(options) -> collapse_options_into_map(__default_options__(), options)
            options when is_map(options) -> options
          end

        with unquote_splicing(checkpoints_with_clauses)
          do

            struct =
              %__MODULE__{
                unquote_splicing(returning_struct_key_values)
              }

            unquote_splicing(implemented_options_call)


          { :ok, struct, rest, options }

        else
          { :wrong_data, wrong_data } -> { :wrong_data, wrong_data } #todo make separate function for error clause raise "Parse of #{__MODULE__} failed. Data was: #{inspect(wrong_data)}"
          :not_enough_bytes -> :not_enough_bytes
          bad_pattern -> raise "Bad pattern returned from parse_returning_options of #{__MODULE__} #{inspect(bad_pattern)}"
        end

      end

    parse_functions =
      if is_should_be_defined_private do

        parse_returning_options =
          quote do
            defp parse_returning_options(_bin = rest, options \\ nil) do
              unquote(parse_function_body)
            end
          end

        parse_function =
          quote do
            defp parse(bin, options \\ nil) do
              case parse_returning_options(bin, options) do
                { :wrong_data, _wrong_data } = wrong_data -> wrong_data
                :not_enough_bytes ->  :not_enough_bytes
                { :ok, struct, rest, _options } -> { :ok, struct, rest }
              end
            end
          end

        parse_decode_function =
          quote do
            defp parse_decode(bin, options \\ nil) do
              case parse(bin, options) do
                { :ok, struct, rest } ->

                  decoded_struct = unquote(env.module).decode(struct, deep: true)

                  { :ok, decoded_struct, rest }
                other_result -> other_result
              end
            end
          end

         [parse_returning_options, parse_function, parse_decode_function]

      else

        parse_returning_options =
          quote do
            def parse_returning_options(_bin = rest, options \\ nil) do
              unquote(parse_function_body)
            end
          end

        parse_function =
          quote do
            def parse(bin, options \\ nil) do
              case parse_returning_options(bin, options) do
                { :wrong_data, _wrong_data } = wrong_data -> wrong_data
                :not_enough_bytes ->  :not_enough_bytes
                { :ok, struct, rest, _options } -> { :ok, struct, rest }
              end
            end
          end

        parse_decode_function =
          quote do
            def parse_decode(bin, options \\ nil) do
              case parse(bin, options) do
                { :ok, struct, rest } ->

                  decoded_struct = unquote(env.module).decode(struct, deep: true)

                  { :ok, decoded_struct, rest }
                other_result -> other_result
              end
            end
          end


          [parse_returning_options, parse_function, parse_decode_function]

      end

    utils = [ ]

    type_conversion_checkpoints_functions ++ parse_checkpoints_functions ++ parse_functions ++ utils

  end

  defp type_conversion_checkpoint_function(checkpoint_index, input_dependencies, output_dependencies) do

    function_name = type_conversion_checkpoint_function_name(checkpoint_index)

    input_binds =
      Enum.map(
        input_dependencies,
        fn input_dependency ->

          case input_dependency do
            %BinStruct.Macro.Structs.DependencyOnField{} = dependency ->

              %BinStruct.Macro.Structs.DependencyOnField{
                field: field
              } = dependency

              name =
                case field do
                  %Field{ name: name } -> name
                  %VirtualField{ name: name } -> name
                end

              Bind.bind_unmanaged_value(name, __MODULE__)

            %BinStruct.Macro.Structs.DependencyOnOption{} -> nil

          end

        end
      ) |> Enum.reject(&is_nil/1)

    output_values =
      Enum.map(
        output_dependencies,

        fn output_dependency ->

          case output_dependency do
            %BinStruct.Macro.Structs.DependencyOnField{} = dependency ->

                %BinStruct.Macro.Structs.DependencyOnField{
                  field: field,
                  type_conversion: type_conversion
                } = dependency

                { name, type } =
                  case field do
                    %Field{ name: name, type: type } -> { name, type }
                    %VirtualField{ name: name, type: type } -> { name, type }
                  end

                unmanaged_value_access = Bind.bind_unmanaged_value(name, __MODULE__)

                case type_conversion do

                  TypeConversionUnspecified ->

                    TypeConverterToManaged.convert_unmanaged_value_to_managed(type, unmanaged_value_access)

                  TypeConversionManaged ->

                    TypeConverterToManaged.convert_unmanaged_value_to_managed(type, unmanaged_value_access).convert_unmanaged_value_to_managed(type, unmanaged_value_access)

                  TypeConversionUnmanaged -> unmanaged_value_access

                  TypeConversionBinary ->

                    TypeConverterToBinary.convert_unmanaged_value_to_binary(type, unmanaged_value_access)

                end

            %BinStruct.Macro.Structs.DependencyOnOption{} -> nil

          end

        end
      ) |> Enum.reject(&is_nil/1)

    quote do

      defp unquote(function_name)(unquote_splicing(input_binds)) do
        { unquote_splicing(output_values)}
      end

    end

  end


  defp parse_checkpoint_function(fields = _checkpoint, checkpoint_index, registered_callbacks_map, env) do

    function_name = parse_checkpoint_function_name(checkpoint_index)

    case fields do
      #if its single element we need check is that optional or unknown
      [ %Field{ opts: opts } = field ] ->

        optional = opts[:optional]
        optional_by = opts[:optional_by]

        size_bits = BinStruct.Macro.FieldSize.field_size_bits(field)

        optional_not_present_clause =
          if optional do
            optional_not_present_parse_checkpoint_function([field], function_name, registered_callbacks_map)
          else
            []
          end

        main_clause =
          case size_bits do
            :unknown -> CheckpointUnknownSize.checkpoint_unknown_size([field], function_name, registered_callbacks_map, env)
            _size when not is_nil(optional_by) -> CheckpointOptionalByOfKnownSize.checkpoint_optional_by_of_known_size([field], function_name, registered_callbacks_map, env)
            _known_size_not_optional_field -> CheckpointKnownSize.checkpoint_known_size([field], function_name, registered_callbacks_map, env)
          end

        [ optional_not_present_clause, main_clause ]

      fields -> CheckpointKnownSize.checkpoint_known_size(fields, function_name, registered_callbacks_map, env)

  end



  end

  defp optional_not_present_parse_checkpoint_function(fields, function_name, registered_callbacks_map) do
    
    dependencies_bindings =
      ParseDependencies.parse_dependencies_excluded_self(fields,registered_callbacks_map)
      |> BindingsToOnFieldDependencies.bindings(__MODULE__)

      quote do

        defp unquote(function_name)(
               "" = _bin,
               unquote_splicing(dependencies_bindings),
               options
             ) do

          { :ok, nil, "", options }

        end

      end


  end

  defp hydrate_parse_checkpoints(checkpoints, [], _registered_callbacks_map), do: Enum.reverse(checkpoints)

  defp hydrate_parse_checkpoints(checkpoints, remain, registered_callbacks_map) do

    { checkpoint, remain } = hydrate_parse_checkpoint_fields([], remain, registered_callbacks_map)

    new_checkpoints = [ checkpoint | checkpoints]

    hydrate_parse_checkpoints(new_checkpoints, remain, registered_callbacks_map)

  end


  defp hydrate_parse_checkpoint_fields(checkpoint, [], _registered_callbacks_map), do: { Enum.reverse(checkpoint), []}

  defp hydrate_parse_checkpoint_fields(checkpoint, [ field | rest ], registered_callbacks_map) do

    size = FieldSize.field_size_bits(field)

    is_optional = BinStruct.Macro.IsOptionalField.is_optional_field(field)

    case size do

      size when is_integer(size) and not is_optional ->

        new_checkpoint = [ field | checkpoint ]

        has_for_cross_checkpoint_dependency_requirements =
          has_for_cross_checkpoint_dependency(
            Enum.reverse(new_checkpoint),
            registered_callbacks_map
          )

        if !has_for_cross_checkpoint_dependency_requirements do
          hydrate_parse_checkpoint_fields(new_checkpoint, rest, registered_callbacks_map)
        else
          produce_checkpoint(checkpoint, field, rest)
        end


      _ -> produce_checkpoint(checkpoint, field, rest)

    end

  end

  defp produce_checkpoint(checkpoint, field, rest) do

    case checkpoint do
      [] -> { [field], rest }
      checkpoint -> { Enum.reverse(checkpoint), [ field | rest ] }
    end

  end

  defp has_for_cross_checkpoint_dependency(checkpoint, registered_callbacks_map) do

    dependencies = ParseDependencies.parse_dependencies_excluded_self(checkpoint, registered_callbacks_map)

    Enum.any?(
      checkpoint,
      fn field ->
        IsFieldDependentOn.is_field_dependent_on(dependencies, field)
      end
    )

  end

  defp parse_checkpoint_function_name(checkpoint_index) do
    String.to_atom("parse_checkpoint_#{checkpoint_index}")
  end

  defp type_conversion_checkpoint_function_name(checkpoint_index) do
    String.to_atom("type_conversion_checkpoint_#{checkpoint_index}")
  end


end