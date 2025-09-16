defmodule BinStruct.Macro.InUseOnlyDefaultOptionsFunction do

  @moduledoc false

  alias BinStruct.Macro.Structs.RegisteredOption
  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument

  def default_options_function(registered_callbacks, children_modules, env) do

    current_module_options =
      Enum.map(
        registered_callbacks,
        fn %RegisteredCallback{} = registered_callback ->

          %RegisteredCallback{ arguments: registered_callback_arguments } = registered_callback

          Enum.map(
            registered_callback_arguments,
            fn registered_callback_argument ->

              case registered_callback_argument do
                %RegisteredCallbackOptionArgument{ registered_option: registered_option } ->

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

                %RegisteredCallbackFieldArgument{} -> nil
              end

            end
          )

        end
      )
      |> List.flatten()
      |> Enum.reject(&is_nil/1)

    children_modules_options =
      Enum.map(
        children_modules,
        fn child_module_full_name ->

          child_default_options = apply(child_module_full_name, :__default_options__, [])

          child_default_options = Enum.filter(child_default_options, fn { k, _v } -> k != :__default_options_initialized__ end)

          Enum.map(
            child_default_options,
            fn { interface, options_map } ->

              Enum.map(
                options_map,
                fn { option_name, value } ->
                  {interface, option_name, value}
                end
              )

            end
          )

        end
      )
      |> List.flatten()

    options_all = current_module_options ++ children_modules_options

    options_all =
      Enum.uniq(options_all)

    options_map =
      Enum.reduce(
        options_all,
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