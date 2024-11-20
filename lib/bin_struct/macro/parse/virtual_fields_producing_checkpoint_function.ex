defmodule BinStruct.Macro.Parse.VirtualFieldsProducingCheckpointFunction do

  @moduledoc false

  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Dependencies.CallbacksDependencies
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies
  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.VirtualFieldProducingCheckpoint
  alias BinStruct.Macro.Dependencies.ExcludeDependenciesOnField

  def receiving_arguments_bindings(%VirtualFieldProducingCheckpoint{} = checkpoint, registered_callbacks_map, context) do

    %VirtualFieldProducingCheckpoint{ virtual_fields: virtual_fields } = checkpoint

    read_by_callbacks =
      Enum.map(
        virtual_fields,
        fn virtual_field ->

          %VirtualField{ opts: opts } = virtual_field

          read_by = Keyword.fetch!(opts, :read_by)

          RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, read_by)

        end
      )

    dependencies = CallbacksDependencies.dependencies(read_by_callbacks)

    receiving_dependencies =
      Enum.reduce(
        virtual_fields,
        dependencies,
        fn virtual_field, dependencies_acc ->
          ExcludeDependenciesOnField.exclude_dependencies_on_field(dependencies_acc, virtual_field)
        end
      )

    BindingsToOnFieldDependencies.bindings(receiving_dependencies, context)

  end

  def output_bindings(%VirtualFieldProducingCheckpoint{} = checkpoint, _registered_callbacks_map, context) do

    %VirtualFieldProducingCheckpoint{ virtual_fields: virtual_fields } = checkpoint

    Enum.map(
      virtual_fields,
      fn virtual_field ->

        %VirtualField{ name: name } = virtual_field

        Bind.bind_managed_value(name, context)

      end
    )

  end

  def virtual_fields_producing_checkpoint_function(
        %VirtualFieldProducingCheckpoint{} = checkpoint,
        function_name,
        registered_callbacks_map,
        _env
      ) do

    receiving_arguments_bindings = receiving_arguments_bindings(checkpoint, registered_callbacks_map, __MODULE__)

    output_bindings = output_bindings(checkpoint, registered_callbacks_map, __MODULE__)

    %VirtualFieldProducingCheckpoint{ virtual_fields: virtual_fields } = checkpoint

    read_by_calls =

      Enum.map(
        virtual_fields,

        fn virtual_field ->

          %VirtualField{ name: field_name, opts: opts } = virtual_field

          registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, opts[:read_by])
          registered_callback_function_call = RegisteredCallbackFunctionCall.registered_callback_function_call(registered_callback, __MODULE__)

          managed_value_bind = Bind.bind_managed_value(field_name, __MODULE__)

          quote do

            unquote(managed_value_bind) = unquote(registered_callback_function_call)

          end

        end
      )


    quote do

      defp unquote(function_name)(unquote_splicing(receiving_arguments_bindings)) do

        unquote_splicing(read_by_calls)

        { unquote_splicing(output_bindings) }

      end

    end

  end


end
