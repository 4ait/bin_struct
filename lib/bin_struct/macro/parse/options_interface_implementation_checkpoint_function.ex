defmodule BinStruct.Macro.Parse.OptionsInterfaceImplementationCheckpointFunction do

  @moduledoc false

  alias BinStruct.Macro.Parse.Structs.OptionsInterfaceImplementationCheckpoint
  alias BinStruct.Macro.Parse.CallInterfaceImplementationsCallbacksAndProduceNewOptions
  alias BinStruct.Macro.Dependencies.InterfaceImplementationDependencies
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies

  def receiving_arguments_bindings(%OptionsInterfaceImplementationCheckpoint{} = checkpoint, registered_callbacks_map, context) do

    %OptionsInterfaceImplementationCheckpoint{ interface_implementations: interface_implementations } = checkpoint

    dependencies = InterfaceImplementationDependencies.interface_implementations_dependencies(interface_implementations, registered_callbacks_map)

    BindingsToOnFieldDependencies.bindings(dependencies, context)

  end

  def options_interface_implementation_checkpoint_function(
        %OptionsInterfaceImplementationCheckpoint{} = checkpoint,
        function_name,
        registered_callbacks_map,
        _env
      ) do

    %OptionsInterfaceImplementationCheckpoint{ interface_implementations: interface_implementations } = checkpoint

    receiving_arguments_bindings = receiving_arguments_bindings(checkpoint, registered_callbacks_map, __MODULE__)

    new_options_expr =
      CallInterfaceImplementationsCallbacksAndProduceNewOptions
      .call_interface_implementations_callbacks_and_produce_new_options(
        interface_implementations,
        registered_callbacks_map,
        __MODULE__
      )

    quote do

      defp unquote(function_name)(unquote_splicing(receiving_arguments_bindings), options) do

        unquote(new_options_expr)

      end

    end

  end


end
