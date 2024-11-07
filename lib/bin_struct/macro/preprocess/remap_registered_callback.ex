defmodule BinStruct.Macro.Preprocess.RemapRegisteredCallback do

  require Logger

  alias BinStruct.Macro.FunctionName
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.FieldsMap
  alias BinStruct.Macro.Structs.RegisteredOptionsMap

  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionBinary
  alias BinStruct.TypeConversion.TypeConversionUnspecified

  def remap_raw_registered_callback(
        raw_registered_callback,
        %FieldsMap{} = fields_map,
        %RegisteredOptionsMap{} = registered_options_map,
        env
      ) do

      { function, raw_arguments } = raw_registered_callback

      case FunctionName.function_name(function, env) do

        function_name when function_name != :unknown ->

          arguments =
            Enum.reduce(
              raw_arguments,
              _arguments_acc = [],

              fn raw_argument, arguments_acc ->

                { name, type } = raw_argument

                { type, _binding } = Code.eval_quoted(type, [], env)

                normalized_type = validate_input_and_normalize_raw_callback_argument(name, type, env)


                argument = remap_raw_callback_argument(name, normalized_type, fields_map, registered_options_map, env)


                arguments_acc ++  [argument]

              end
            )

           arguments = List.flatten(arguments)

           %RegisteredCallback{
             function: function,
             arguments: arguments
           }

        :unknown -> raise "not a function reference (&), given: #{inspect(function)}"

      end

  end


  defp validate_input_and_normalize_raw_callback_argument(name, type, env)  do

    case type do
      type_map when is_map(type_map) ->

        valid_keys = [:type, :interface, :type_conversion]

        if Enum.all?(Map.keys(type_map), &(&1 in valid_keys)) do
          type_map
        else
          raise "not supported argument for #{name}, given: #{inspect(type_map)}, valid map keys are: #{inspect(valid_keys)}"
        end

      type_atom when is_atom(type) ->

        case type_atom do
          :field -> %{ type: :field }
          :option -> %{ type: :option, interface: env.module }
          _else -> raise "not supported argument for #{name}, given: #{inspect(type_atom)}, valid arguments are: #{inspect([:field, :option])}"
        end

    end

  end

  defp remap_raw_callback_argument(
         name,
         %{} = argument_type_map,
         %FieldsMap{} = fields_map,
         %RegisteredOptionsMap{} = registered_options_map,
         _env
       ) do

      case argument_type_map do

        %{ type: :field } ->

          %RegisteredCallbackFieldArgument{
            field: FieldsMap.get_field_by_name(fields_map, name),
            type_conversion: type_conversion_from_argument_type_map(argument_type_map)
          }

          %{ type: :option, interface: interface } ->

            %RegisteredCallbackOptionArgument{
              registered_option: RegisteredOptionsMap.get_registered_option_by_interface_and_name(registered_options_map, interface, name)
            }

      end

  end

  defp type_conversion_from_argument_type_map(argument_type_map) do

    type_conversion = argument_type_map[:type_conversion]

    case type_conversion do
      TypeConversionManaged -> TypeConversionManaged
      TypeConversionUnmanaged -> TypeConversionUnmanaged
      TypeConversionBinary -> TypeConversionBinary
      TypeConversionUnspecified -> TypeConversionUnspecified

      nil -> TypeConversionUnspecified

      _ -> raise "Type conversion argument support values from BinStruct.TypeConversion, given: #{inspect(type_conversion)}"

    end
    

  end


end