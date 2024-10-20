defmodule BinStruct.Macro.ParseFunction do

  alias BinStruct.Macro.FieldSize
  alias BinStruct.Macro.Bind

  alias BinStruct.Macro.Parse.CheckpointKnownSize
  alias BinStruct.Macro.Parse.CheckpointOptionalByOfKnownSize
  alias BinStruct.Macro.Parse.CheckpointUnknownSize
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Parse.MaybeCallInterfaceImplementationCallbacksAndCollapseNewOptions
  alias BinStruct.Macro.Parse.ExternalFieldDependencies


  def parse_function(fields, interface_implementations, registered_callbacks_map, env, is_should_be_defined_private) do

    checkpoints = hydrate_checkpoints([], fields)

    checkpoints_functions =
      Enum.with_index(checkpoints, 1)
      |> Enum.map(
           fn {checkpoint, index} ->
             checkpoint_function(
               checkpoint,
               index,
               interface_implementations,
               registered_callbacks_map,
               env
             )
           end)
      |> List.flatten()

    checkpoints_with_clauses =
      Enum.map(
        Enum.with_index(checkpoints, 1),
        fn {fields, index} ->

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

          returning_from_checkpoint_values_binds =
            Enum.map(
              fields,
              fn %Field{} = field ->

                %Field{ name: name } = field

                { Bind.bind_value_name(name), [], __MODULE__ }
              end
            )

          quote do
            { :ok, unquote_splicing(returning_from_checkpoint_values_binds), rest, options } <-
              unquote(checkpoint_function_name(index))(rest, unquote_splicing(value_arguments_binds), options)
          end

        end
      )

    returning_struct_key_values =
      Enum.map(
        checkpoints,
        fn fields ->

          Enum.map(
            fields,
            fn %Field{} = field ->

               %Field{ name: name } = field

               value = { Bind.bind_value_name(name), [], __MODULE__ }

              { name, value }

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

    checkpoints_functions ++ parse_functions ++ utils

  end


  defp checkpoint_function(fields = _checkpoint, checkpoint_index, interface_implementations, registered_callbacks_map, env) do

    function_name = checkpoint_function_name(checkpoint_index)

    case fields do
      #if its single element we need check is that optional or unknown
      [ %Field{ opts: opts } = field ] ->

        optional = opts[:optional]
        optional_by = opts[:optional_by]

        size_bits = BinStruct.Macro.FieldSize.field_size_bits(field)

        optional_not_present_clause =
          if optional do
            optional_not_present_checkpoint_function([field], function_name, interface_implementations, registered_callbacks_map)
          else
            []
          end

        main_clause =
          case size_bits do
            :unknown -> CheckpointUnknownSize.checkpoint_unknown_size([field], function_name, interface_implementations, registered_callbacks_map, env)
            _size when not is_nil(optional_by) -> CheckpointOptionalByOfKnownSize.checkpoint_optional_by_of_known_size([field], function_name, interface_implementations, registered_callbacks_map, env)
            _known_size_not_optional_field -> CheckpointKnownSize.checkpoint_known_size([field], function_name, interface_implementations, registered_callbacks_map, env)
          end

        [ optional_not_present_clause, main_clause ]

      fields -> CheckpointKnownSize.checkpoint_known_size(fields, function_name, interface_implementations, registered_callbacks_map, env)

  end



  end

  defp optional_not_present_checkpoint_function(fields, function_name, interface_implementations, registered_callbacks_map) do

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

      quote do

        defp unquote(function_name)(
               "" = _bin,
               unquote_splicing(value_arguments_binds),
               options
             ) do

          { :ok, nil, "", options }

        end

      end


  end

  defp hydrate_checkpoints(checkpoints, []), do: Enum.reverse(checkpoints)

  defp hydrate_checkpoints(checkpoints, remain) do

    {checkpoint, remain} = hydrate_checkpoint_fields([], remain)

    new_checkpoints = [ checkpoint | checkpoints]

    hydrate_checkpoints(new_checkpoints, remain)

  end


  defp hydrate_checkpoint_fields(checkpoint, []), do: { Enum.reverse(checkpoint), []}

  defp hydrate_checkpoint_fields(checkpoint, [ field | rest ]) do

    size = FieldSize.field_size_bits(field)

    is_optional = BinStruct.Macro.IsOptionalField.is_optional_field(field)

    case size do

      size when is_integer(size) and not is_optional ->

        new_checkpoint = [ field | checkpoint ]
        hydrate_checkpoint_fields(new_checkpoint, rest)

      _ ->

        case checkpoint do
          [] -> { [field], rest }
          checkpoint -> { Enum.reverse(checkpoint), [ field | rest ] }
        end

    end

  end

  defp checkpoint_function_name(checkpoint_index) do
    String.to_atom("parse_checkpoint_#{checkpoint_index}")
  end


end