defmodule BinStruct.Macro.ParseFunction do

  alias BinStruct.Macro.FieldSize
  alias BinStruct.Macro.Bind

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.IsOptionalField

  alias BinStruct.Macro.Parse.TypeConversionCheckpointFunction
  alias BinStruct.Macro.Parse.VirtualFieldsProducingCheckpointFunction
  alias BinStruct.Macro.Parse.OptionsInterfaceImplementationCheckpointFunction
  alias BinStruct.Macro.Parse.ParseTopology
  alias BinStruct.Macro.Parse.ParseTopologyNodes.ParseNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.TypeConversionNode
  alias BinStruct.Macro.Parse.ParseTopologyNodes.VirtualFieldProducingNode
  alias BinStruct.Macro.Structs.ParseCheckpoint
  alias BinStruct.Macro.Structs.TypeConversionCheckpoint
  alias BinStruct.Macro.Structs.VirtualFieldProducingCheckpoint
  alias BinStruct.Macro.Structs.OptionsInterfaceImplementationCheckpoint
  alias BinStruct.Macro.Parse.ParseCheckpointFunction
  alias BinStruct.Macro.Parse.ParseTopologyNodes.InterfaceImplementationNode

  def parse_function(fields, interface_implementations, registered_callbacks_map, env, is_should_be_defined_private) do

    parse_topology = ParseTopology.topology(fields, registered_callbacks_map, interface_implementations)

    checkpoints = create_checkpoints_from_topology(parse_topology)

    checkpoint_functions =
      Enum.map(
        Enum.with_index(checkpoints, 1),

           fn { checkpoint, index } ->

            case checkpoint do

              %ParseCheckpoint{} = parse_checkpoint ->

              ParseCheckpointFunction.parse_checkpoint_function(
                parse_checkpoint,
                  parse_checkpoint_function_name(index),
                  registered_callbacks_map,
                  env
                )

              %TypeConversionCheckpoint{} = type_conversion_checkpoint ->

                TypeConversionCheckpointFunction.type_conversion_checkpoint_function(
                  type_conversion_checkpoint,
                  type_conversion_checkpoint_function_name(index),
                  registered_callbacks_map,
                  env
                )

              %VirtualFieldProducingCheckpoint{} = virtual_field_producing_checkpoint ->

                VirtualFieldsProducingCheckpointFunction.virtual_fields_producing_checkpoint_function(
                  virtual_field_producing_checkpoint,
                  virtual_fields_producing_checkpoint_function_name(index),
                  registered_callbacks_map,
                  env
                )

              %OptionsInterfaceImplementationCheckpoint{} = options_interface_implementation_checkpoint ->

                OptionsInterfaceImplementationCheckpointFunction.options_interface_implementation_checkpoint_function(
                  options_interface_implementation_checkpoint,
                  interface_implementation_checkpoint_function_name(index),
                  registered_callbacks_map,
                  env
                )

            end

           end)

      |> List.flatten()


    checkpoints_with_clauses =
      Enum.map(
        Enum.with_index(checkpoints, 1),
        fn { checkpoint, index } ->

          case checkpoint do
            %ParseCheckpoint{} = parse_checkpoint ->

              receiving_arguments_bindings =
                ParseCheckpointFunction.receiving_arguments_bindings(
                  parse_checkpoint,
                  registered_callbacks_map,
                  __MODULE__
                )

              output_bindings =
                ParseCheckpointFunction.output_bindings(
                  parse_checkpoint,
                  registered_callbacks_map,
                  __MODULE__
                )

              quote do

                { :ok, unquote_splicing(output_bindings), rest, options } <-

                  unquote(parse_checkpoint_function_name(index))(
                    rest,
                    unquote_splicing(receiving_arguments_bindings),
                    options
                  )

              end

            %TypeConversionCheckpoint{} = type_conversion_checkpoint ->


              receiving_arguments_bindings =
                TypeConversionCheckpointFunction.receiving_arguments_bindings(
                  type_conversion_checkpoint,
                  registered_callbacks_map,
                  __MODULE__
                )

              output_bindings =
                TypeConversionCheckpointFunction.output_bindings(
                  type_conversion_checkpoint,
                  registered_callbacks_map,
                  __MODULE__
                )

              quote do
                { unquote_splicing(output_bindings) } <-

                  unquote(type_conversion_checkpoint_function_name(index))(
                    unquote_splicing(receiving_arguments_bindings)
                  )

              end

            %VirtualFieldProducingCheckpoint{} = virtual_field_producing_checkpoint ->

              receiving_arguments_bindings =
                VirtualFieldsProducingCheckpointFunction.receiving_arguments_bindings(
                  virtual_field_producing_checkpoint,
                  registered_callbacks_map,
                  __MODULE__
                )

              output_bindings =
                VirtualFieldsProducingCheckpointFunction.output_bindings(
                  virtual_field_producing_checkpoint,
                  registered_callbacks_map,
                  __MODULE__
                )

              quote do
                { unquote_splicing(output_bindings) } <-

                  unquote(virtual_fields_producing_checkpoint_function_name(index))(
                    unquote_splicing(receiving_arguments_bindings)
                  )

              end

            %OptionsInterfaceImplementationCheckpoint{} = interface_implementation_checkpoint ->

              receiving_arguments_bindings =
                OptionsInterfaceImplementationCheckpointFunction.receiving_arguments_bindings(
                  interface_implementation_checkpoint,
                  registered_callbacks_map,
                  __MODULE__
                )

              quote do
                options <-

                  unquote(interface_implementation_checkpoint_function_name(index))(
                    unquote_splicing(receiving_arguments_bindings),
                    options
                  )

              end

          end


        end
      ) |> List.flatten()

    returning_struct_key_values =
      Enum.map(
        fields,
        fn field ->

          %Field{ name: name } = field

          { name, Bind.bind_unmanaged_value(name, __MODULE__) }

        end
      ) |> List.flatten()

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


         [parse_returning_options, parse_function]

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


          [parse_returning_options, parse_function]

      end

    checkpoint_functions ++ parse_functions

  end



  defp create_checkpoints_from_topology(parse_topology) do
    create_checkpoints_from_topology_rec(parse_topology, nil, [])
  end

  defp create_checkpoints_from_topology_rec([], current_checkpoint, checkpoints_acc) do

    checkpoints_acc =
      case current_checkpoint do
        nil -> checkpoints_acc
        current_checkpoint -> [ current_checkpoint | checkpoints_acc ]
      end

    Enum.reverse(checkpoints_acc)

  end

  defp create_checkpoints_from_topology_rec([ head_node | remain_nodes ], current_checkpoint, checkpoints_acc) do

    case head_node do

      %ParseNode{} = parse_node ->
        add_parse_node(parse_node, remain_nodes, current_checkpoint, checkpoints_acc)

      %TypeConversionNode{} = type_conversion_node ->
        add_type_conversion_node(type_conversion_node, remain_nodes, current_checkpoint, checkpoints_acc)

      %VirtualFieldProducingNode{} = virtual_field_producing_node ->
        add_virtual_field_producing_node(virtual_field_producing_node, remain_nodes, current_checkpoint, checkpoints_acc)

      %InterfaceImplementationNode{} = interface_implementation_node ->
        add_interface_implementation_node(interface_implementation_node, remain_nodes, current_checkpoint, checkpoints_acc)
    end

  end

  defp add_parse_node(%ParseNode{} = parse_node, remain_nodes, current_checkpoint, checkpoints_acc) do

    %ParseNode{ field: field } = parse_node

    case current_checkpoint do

      %ParseCheckpoint{ fields: fields } ->

        fields_combined = fields ++ [field]

        if can_combine_fields_to_single_parse_checkpoint?(fields_combined) do

          current_checkpoint = %ParseCheckpoint{ fields: fields_combined }

          create_checkpoints_from_topology_rec(
            remain_nodes,
            current_checkpoint,
            checkpoints_acc
          )

        else

          next_checkpoint = %ParseCheckpoint{ fields: [ field ] }

          create_checkpoints_from_topology_rec(
            remain_nodes,
            next_checkpoint,
            [ current_checkpoint | checkpoints_acc ]
          )

        end

      _ ->

        next_checkpoint = %ParseCheckpoint{ fields: [ field ] }

        case current_checkpoint do

          nil ->

            create_checkpoints_from_topology_rec(
              remain_nodes,
              next_checkpoint,
              checkpoints_acc
            )

          current_checkpoint ->

            create_checkpoints_from_topology_rec(
              remain_nodes,
              next_checkpoint,
              [ current_checkpoint | checkpoints_acc ]
            )

        end

    end

  end



  defp add_type_conversion_node(%TypeConversionNode{} = type_conversion_node, remain_nodes, current_checkpoint, checkpoints_acc) do


    case current_checkpoint do

      %TypeConversionCheckpoint{ type_conversion_nodes: type_conversion_nodes } ->

        next_checkpoint = %TypeConversionCheckpoint{ type_conversion_nodes: type_conversion_nodes ++ [ type_conversion_node ] }

        create_checkpoints_from_topology_rec(
          remain_nodes,
          next_checkpoint,
          checkpoints_acc
        )

      _ ->

        next_checkpoint = %TypeConversionCheckpoint{ type_conversion_nodes: [ type_conversion_node ] }

        case current_checkpoint do

          nil ->

            create_checkpoints_from_topology_rec(
              remain_nodes,
              next_checkpoint,
              checkpoints_acc
            )

          current_checkpoint ->

            create_checkpoints_from_topology_rec(
              remain_nodes,
              next_checkpoint,
              [ current_checkpoint | checkpoints_acc ]
            )

        end

    end

  end


  defp add_virtual_field_producing_node(%VirtualFieldProducingNode{} = virtual_field_producing_node, remain_nodes, current_checkpoint, checkpoints_acc) do


    %VirtualFieldProducingNode{ virtual_field: virtual_field } = virtual_field_producing_node

    case current_checkpoint do

      %VirtualFieldProducingCheckpoint{ virtual_fields: virtual_fields } ->

        next_checkpoint = %VirtualFieldProducingCheckpoint{ virtual_fields: virtual_fields ++ [ virtual_field ] }

        create_checkpoints_from_topology_rec(
          remain_nodes,
          next_checkpoint,
          checkpoints_acc
        )

      _ ->

        next_checkpoint = %VirtualFieldProducingCheckpoint{ virtual_fields: [ virtual_field ] }

        case current_checkpoint do

          nil ->

            create_checkpoints_from_topology_rec(
              remain_nodes,
              next_checkpoint,
              checkpoints_acc
            )

          current_checkpoint ->

            create_checkpoints_from_topology_rec(
              remain_nodes,
              next_checkpoint,
              [ current_checkpoint | checkpoints_acc ]
            )

        end

    end

  end

  defp add_interface_implementation_node(%InterfaceImplementationNode{} = interface_implementation_node, remain_nodes, current_checkpoint, checkpoints_acc) do


    %InterfaceImplementationNode{ interface_implementation: interface_implementation } = interface_implementation_node

    case current_checkpoint do

      %OptionsInterfaceImplementationCheckpoint{ interface_implementations: interface_implementations } ->

        next_checkpoint =
          %OptionsInterfaceImplementationCheckpoint{
            interface_implementations: interface_implementations ++ [ interface_implementation ]
          }

        create_checkpoints_from_topology_rec(
          remain_nodes,
          next_checkpoint,
          checkpoints_acc
        )

      _ ->

        next_checkpoint = %OptionsInterfaceImplementationCheckpoint{ interface_implementations: [ interface_implementation ] }

        case current_checkpoint do

          nil ->

            create_checkpoints_from_topology_rec(
              remain_nodes,
              next_checkpoint,
              checkpoints_acc
            )

          current_checkpoint ->

            create_checkpoints_from_topology_rec(
              remain_nodes,
              next_checkpoint,
              [ current_checkpoint | checkpoints_acc ]
            )

        end

    end

  end

  defp can_combine_fields_to_single_parse_checkpoint?(fields) do

    Enum.all?(
      fields,
      fn field ->

        size = FieldSize.field_size_bits(field)

        is_optional = IsOptionalField.is_optional_field(field)

        case size do

          size when is_integer(size) and not is_optional -> true

          _ -> false

        end

      end
    )

  end

  defp parse_checkpoint_function_name(checkpoint_index) do
    String.to_atom("parse_checkpoint_#{checkpoint_index}")
  end

  defp type_conversion_checkpoint_function_name(checkpoint_index) do
    String.to_atom("type_conversion_checkpoint_#{checkpoint_index}")
  end

  defp virtual_fields_producing_checkpoint_function_name(checkpoint_index) do
    String.to_atom("virtual_fields_producing_checkpoint_#{checkpoint_index}")
  end

  defp interface_implementation_checkpoint_function_name(checkpoint_index) do
    String.to_atom("interface_implementation_checkpoint_#{checkpoint_index}")
  end

end