defmodule BinStruct.Macro.Parse.VirtualFieldsProducingCheckpointFunction do


  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.Structs.DependencyOnOption
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Dependencies.CallbacksDependencies
  alias BinStruct.Macro.Dependencies.DeconstructionOfOnOptionDependencies
  alias BinStruct.Macro.Dependencies.BindingsToOnFieldDependencies
  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.Structs.VirtualFieldProducingCheckpoint


  def receiving_arguments_bindings(%VirtualFieldProducingCheckpoint{} = checkpoint, registered_callbacks_map, context) do

    %VirtualFieldProducingCheckpoint{ fields: fields } = checkpoint

    dependencies = ParseDependencies.parse_dependencies_excluded_self(fields, registered_callbacks_map)

    BindingsToOnFieldDependencies.bindings(dependencies, context)

  end

  def output_bindings(%VirtualFieldProducingCheckpoint{} = checkpoint, registered_callbacks_map, context) do

    %VirtualFieldProducingCheckpoint{ fields: fields } = checkpoint

    Enum.map(
      fields,
      fn field ->

        %Field{ name: name } = field

        Bind.bind_unmanaged_value(name, context)

      end
    )

  end

  def input_dependencies_OLD(virtual_fields, registered_callbacks_map) do

    read_by_callbacks =
      Enum.map(
        virtual_fields,
        fn virtual_field ->

          %VirtualField{ opts: opts } = virtual_field

          read_by = Keyword.fetch!(opts, :read_by)

          RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, read_by)

        end
      )

    CallbacksDependencies.dependencies(read_by_callbacks)

  end

  def virtual_fields_producing_checkpoint_function(
        %VirtualFieldProducingCheckpoint{} = checkpoint,
        function_name,
        registered_callbacks_map,
        _env
      ) do

    input_dependencies = input_dependencies(virtual_fields, registered_callbacks_map)

    dependencies_bindings = BindingsToOnFieldDependencies.bindings(input_dependencies, __MODULE__)

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

    returns =
      Enum.map(
        virtual_fields,
        fn  virtual_field ->

          %VirtualField{ name: field_name, opts: opts } = virtual_field

          Bind.bind_managed_value(field_name, __MODULE__)

        end
      )

    quote do

      defp unquote(function_name)(unquote_splicing(dependencies_bindings), options) do

        unquote(
          DeconstructionOfOnOptionDependencies.option_dependencies_deconstruction(input_dependencies, __MODULE__)
        )

        unquote_splicing(read_by_calls)

        { unquote_splicing(returns) }

      end

    end

  end

  defp old() do

    input_binds =
      Enum.map(
        input_dependencies,
        fn input_dependency ->

          case input_dependency do
            %DependencyOnField{} = dependency ->

              %DependencyOnField{
                field: field
              } = dependency

              name =
                case field do
                  %Field{ name: name } -> name
                  %VirtualField{ name: name } -> name
                end

              Bind.bind_unmanaged_value(name, __MODULE__)

            %DependencyOnOption{} -> nil

          end

        end
      ) |> Enum.reject(&is_nil/1)

    output_binds =
      Enum.map(
        output_dependencies,
        fn output_dependency ->

          case output_dependency do

            %DependencyOnField{} = dependency ->

              %DependencyOnField{
                field: field,
                type_conversion: type_conversion
              } = dependency

              name =
                case field do
                  %Field{ name: name } -> name
                  %VirtualField{ name: name } -> name
                end

              case type_conversion do
                TypeConversionUnspecified -> Bind.bind_managed_value(name, __MODULE__)
                TypeConversionManaged -> Bind.bind_managed_value(name, __MODULE__)
                TypeConversionUnmanaged -> Bind.bind_unmanaged_value(name, __MODULE__)
                TypeConversionBinary-> Bind.bind_binary_value(name, __MODULE__)
              end

            %DependencyOnOption{} -> nil

          end

        end
      ) |> Enum.reject(&is_nil/1)

    quote do
      { unquote_splicing(output_binds) } <- unquote(type_conversion_checkpoint_function_name(index))(unquote_splicing(input_binds))
    end

  end


end
