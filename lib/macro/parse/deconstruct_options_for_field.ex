defmodule BinStruct.Macro.Parse.DeconstructOptionsForField do

  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Parse.CallbacksDependenciesAll
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.Structs.RegisteredOption
  alias BinStruct.Macro.CallbacksOnField
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap

  def deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, context) do

    deconstruct_options_for_fields([field],  interface_implementations, registered_callbacks_map, context)

  end

  def deconstruct_options_for_fields(fields, interface_implementations, registered_callbacks_map, context) do


    options_bind_access = { :options, [], context }

    callbacks = CallbacksOnField.callbacks_used_while_parsing(fields, registered_callbacks_map)


    option_dependencies_all = CallbacksDependenciesAll.option_dependencies_all(fields, interface_implementations, registered_callbacks_map)

    options_dependencies_by_interface =
      Enum.group_by(
        option_dependencies_all,
        fn %RegisteredCallbackOptionArgument{} = option_argument ->

          %RegisteredCallbackOptionArgument{
            registered_option: %RegisteredOption{ interface: interface }
          } = option_argument

          interface

        end
      )

    interfaces_deconstructing_key_values =
      Enum.map(
        options_dependencies_by_interface,
        fn interface_with_options ->

          { interface, option_arguments } = interface_with_options

          interface_values =
            Enum.map(
              option_arguments,
              fn %RegisteredCallbackOptionArgument{} = option_argument ->

                %RegisteredCallbackOptionArgument{
                  registered_option: %RegisteredOption{ interface: interface, name: name }
                } = option_argument

                { name, Bind.bind_option(interface, name, context) }

              end
            )

          interface_values_map =
            quote do
              %{ unquote_splicing(interface_values) }
            end

          { _key = interface, interface_values_map }

        end
      )

    quote do
      %{
        unquote_splicing(interfaces_deconstructing_key_values)
      } = unquote(options_bind_access)
    end

  end

  defp registered_version_of_callbacks(callbacks, registered_callbacks_map) do

    Enum.map(
      callbacks,
      fn callback ->
        RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, callback)
      end
    )

  end



end