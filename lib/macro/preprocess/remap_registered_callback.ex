defmodule BinStruct.Macro.Preprocess.RemapRegisteredCallback do

  require Logger

  alias BinStruct.Macro.FunctionName
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackItemArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackNewArgument
  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.FieldsMap
  alias BinStruct.Macro.Structs.RegisteredOptionsMap

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


  defp normalize_raw_callback_argument(name, type, fields_map, registered_options_map, env) when not is_map(type)  do

    argument_type =
      case type do
        :field -> %{ type: :field }
        :option -> %{ type: :option, interface: env.module }
        :item -> %{ type: :item }
        :argument -> %{ type: :argument }
      end

    normalize_raw_callback_argument(name, argument_type, fields_map, registered_options_map, env)

  end

  defp normalize_raw_callback_argument(
         name,
         %{} = argument_type,
         %FieldsMap{} = fields_map,
         %RegisteredOptionsMap{} = registered_options_map,
         _env
       ) do

      case argument_type do

          %{ type: :option, interface: interface } ->

            %RegisteredCallbackOptionArgument{
              registered_option: RegisteredOptionsMap.get_registered_option_by_interface_and_name(registered_options_map, interface, name)
            }

          %{ type: :field } = type_map ->

            %RegisteredCallbackFieldArgument{
              field: FieldsMap.get_field_by_name(fields_map, name),
              options: Map.delete(type_map, :type)
            }

          %{ type: :item } = type_map ->

            %RegisteredCallbackItemArgument{
              item_of_field: FieldsMap.get_field_by_name(fields_map, name),
              options: Map.delete(type_map, :type)
            }

        %{ type: :argument } = type_map ->

          %RegisteredCallbackNewArgument{
            field: FieldsMap.get_field_by_name(fields_map, name),
            options: Map.delete(type_map, :type)
          }

      end

  end


end