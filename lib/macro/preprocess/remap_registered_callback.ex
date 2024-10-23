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

          arguments_and_returns =
            Enum.reduce(
              raw_arguments,
              %{
                arguments: [],
                returns: :unspecified
              },
              fn raw_argument, %{} = acc ->

                { name, type } = raw_argument

                { type, _binding } = Code.eval_quoted(type, [], env)

                case { name, type } do

                  {:returns, return_fields } when is_list(return_fields) ->

                    %{
                      acc |
                      returns:
                        Enum.map(
                          return_fields,
                          fn return_field ->
                            FieldsMap.get_field_by_name(fields_map, return_field)
                          end
                        )
                    }

                  {:arguments, arguments } when is_list(arguments) ->

                    arguments =
                      Enum.map(
                        arguments,
                        fn argument ->

                          { name, type } = argument

                          normalize_raw_callback_argument(name, type, fields_map, registered_options_map, env)

                        end
                      )

                    %{
                      arguments: current_arguments
                    } = acc

                    %{
                      acc |
                      arguments: current_arguments ++ arguments
                    }

                  { name, type } ->

                    argument = normalize_raw_callback_argument(name, type, fields_map, registered_options_map, env)

                    %{
                      arguments: current_arguments
                    } = acc

                    %{
                      acc |
                      arguments: current_arguments ++ [argument]
                    }

                end

              end
            )

           %{
             arguments: arguments,
             returns: returns
           } = arguments_and_returns

           arguments = List.flatten(arguments)

           %RegisteredCallback{
             function: function,
             arguments: arguments,
             returns: returns
           }

        :unknown -> raise "not a function reference (&), given: #{inspect(function)}"

      end

  end


  defp normalize_raw_callback_argument(name, type_atom, fields_map, registered_options_map, env) when is_atom(type_atom)  do

    argument_type =
      case type_atom do
        :field -> %{ type: :field }
        :option -> %{ type: :option, interface: env.module }
      end

    normalize_raw_callback_argument(name, argument_type, fields_map, registered_options_map, env)

  end

  defp normalize_raw_callback_argument(
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