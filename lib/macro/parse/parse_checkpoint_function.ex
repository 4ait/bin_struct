defmodule BinStruct.Macro.Parse.ParseCheckpointFunction do


  alias BinStruct.Macro.FieldSize
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Parse.CheckpointUnknownSize
  alias BinStruct.Macro.Parse.CheckpointKnownSize
  alias BinStruct.Macro.Parse.CheckpointOptionalByOfKnownSize
  alias BinStruct.Macro.Dependencies.ParseDependencies
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies
  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.ParseCheckpoint

  def receiving_arguments_bindings(%ParseCheckpoint{} = checkpoint, registered_callbacks_map, context) do

    %ParseCheckpoint{ fields: fields } = checkpoint

    dependencies = ParseDependencies.parse_dependencies_excluded_self(fields, registered_callbacks_map)

    BindingsToOnFieldDependencies.bindings(dependencies, context)

  end

  def output_bindings(%ParseCheckpoint{} = checkpoint, registered_callbacks_map, context) do

    %ParseCheckpoint{ fields: fields } = checkpoint

    Enum.map(
      fields,
      fn field ->

        %Field{ name: name } = field

        Bind.bind_unmanaged_value(name, context)

      end
    )

  end

  def parse_checkpoint_function(%ParseCheckpoint{} = checkpoint, function_name, registered_callbacks_map, env) do


    %ParseCheckpoint{ fields: fields } = checkpoint

    case fields do
      #if its single element we need check is that optional or unknown
      [ %Field{ opts: opts } = field ] ->

        optional = opts[:optional]
        optional_by = opts[:optional_by]

        size_bits = FieldSize.field_size_bits(field)

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

end
