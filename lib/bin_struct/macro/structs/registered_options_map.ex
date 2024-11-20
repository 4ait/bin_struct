defmodule BinStruct.Macro.Structs.RegisteredOptionsMap do

  @moduledoc false

  alias BinStruct.Macro.Structs.RegisteredOptionsMap
  alias BinStruct.Macro.Structs.RegisteredOption

  defstruct [
    :registered_options_map
  ]

  def new(registered_options, env) do
    %RegisteredOptionsMap{
      registered_options_map: registered_options_make_map(registered_options, env)
    }
  end

  def get_registered_option_by_interface_and_name(self, interface, option_name) do

    %{ registered_options_map: registered_options_map } = self

    case registered_options_map do

      #this is implicit options interface of current module
      %{ ^interface => interface_options } ->

        %{ ^option_name => registered_option } = interface_options

        registered_option

      #need to access interface module and fetch registered options before
      _ ->

        registered_options_map_of_remote_module = apply(interface, :__registered_options_map__, [])

        RegisteredOptionsMap.get_registered_option_by_interface_and_name(
          registered_options_map_of_remote_module,
          interface,
          option_name
        )

    end

  end

  defp registered_options_make_map(registered_options, _env) do

    Enum.reduce(
      registered_options,
      %{},
      fn %RegisteredOption{} = registered_option, acc ->

        %RegisteredOption{ interface: interface, name: name } = registered_option

        case acc do

          %{ ^interface => interface_options } = map ->

            interface_map = Map.put(interface_options, name, registered_option)

              %{
              map |
              interface => interface_map
            }

          %{} = map ->

            interface_map = Map.put(%{}, name, registered_option)

            Map.put(
              map,
              interface,
              interface_map
            )

        end

      end
    )

  end

end
