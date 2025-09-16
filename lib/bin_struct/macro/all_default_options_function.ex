defmodule BinStruct.Macro.AllDefaultOptionsFunction do

  @moduledoc false

  alias BinStruct.Macro.Structs.RegisteredOption

  def default_options_function(registered_options, env) do

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

    module_full_name = Macro.expand(env.module, env)

    options_map =

      case options_map do

        %{ __default_options_initialized__: initialized_modules_map } ->

          Map.put(
            options_map,
            :__default_options_initialized__,
            MapSet.put(initialized_modules_map, module_full_name)
          )

        %{} ->

          Map.put(
            options_map,
            :__default_options_initialized__,
            MapSet.new([module_full_name])
          )

      end

    quote do

      def __default_options__() do

        unquote(
          Macro.escape(options_map)
        )

      end

    end

  end

end