defmodule BinStruct.Macro.AllDefaultOptionsFunction do

  alias BinStruct.Macro.Structs.RegisteredOption

  def default_options_function(registered_options, _env) do

    current_module_options =
      Enum.map(
        registered_options,
        fn %RegisteredOption{} = registered_option ->

          %RegisteredOption{
            name: name,
            interface: interface,
            parameters: parameters
          } = registered_option

          default_value =
            case parameters[:default] do
              default when not is_nil(default) -> default
              _ -> nil
            end

          first_key = interface
          second_key = name

          { first_key, second_key, default_value }

        end
      )

    options_map =
      Enum.reduce(
        current_module_options,
        %{},
        fn option, acc ->

          { interface, option_name, option_value } = option

          case acc do
            %{ ^interface => interface_map } = map ->

              updated_interface_map =
                Map.put(
                  interface_map,
                  option_name,
                  option_value
                )

              %{
                map |
                interface => updated_interface_map
              }

            %{} = map ->

              new_interface =
                %{
                  option_name => option_value
                }

              Map.put(map, interface, new_interface)

          end

        end
      )

    quote do

      def __default_options__() do

        unquote(
          Macro.escape(options_map)
        )

      end

    end

  end

end