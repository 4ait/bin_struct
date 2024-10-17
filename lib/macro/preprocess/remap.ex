defmodule BinStruct.Macro.Preprocess.Remap do

  alias BinStruct.Macro.Preprocess.RemapType
  alias BinStruct.Macro.Preprocess.RemapCallbackOptions
  alias BinStruct.Macro.Preprocess.RemapRegisteredCallback
  alias BinStruct.Macro.Preprocess.RemapRegisteredOption
  alias BinStruct.Macro.Preprocess.RemapInterfaceImplementation
  alias BinStruct.Macro.Structs.FieldsMap
  alias BinStruct.Macro.Structs.RegisteredOptionsMap

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.Structs.OneOfPack

  def remap_raw_fields_and_one_of_packs(raw_fields_or_packs, env) do

    Enum.map(
      raw_fields_or_packs,
      fn raw_field_or_pack ->

         case raw_field_or_pack do

           { :one_of_pack, raw_fields } ->

            fields =
              Enum.map(
                raw_fields,
                fn raw_field ->
                  remap_raw_field(raw_field, env)
                end
              )

            %OneOfPack{
              fields: fields
            }

           { :virtual_field, _name, _type, _opts } = raw_virtual_field ->  remap_raw_virtual_field(raw_virtual_field, env)

           { _name, _type, _opts } = raw_field -> remap_raw_field(raw_field, env)

         end

      end
    )

  end

  defp remap_raw_field({ name, type, opts } = _raw_field, env) do

    new_opts = RemapCallbackOptions.remap_callback_options(opts, env)
    new_type = RemapType.remap_type(type, new_opts, env)

    %Field {
      name: name,
      type: new_type,
      opts: new_opts
    }

  end

  defp remap_raw_virtual_field({ :virtual_field, name, type, opts } = _raw_virtual_field, env) do

    new_opts = RemapCallbackOptions.remap_callback_options(opts, env)
    new_type = RemapType.remap_type(type, new_opts, env)

    %VirtualField {
      name: name,
      type: new_type,
      opts: new_opts
    }

  end

  def remap_raw_registered_callbacks(raw_registered_callbacks, fields, registered_options, env) do

    fields_map = FieldsMap.new(fields, env)
    registered_options_map = RegisteredOptionsMap.new(registered_options, env)

    Enum.map(
      raw_registered_callbacks,
      fn raw_registered_callback->
         RemapRegisteredCallback.remap_raw_registered_callback(raw_registered_callback, fields_map, registered_options_map, env)
      end
    )

  end

  def remap_raw_registered_options(raw_registered_options, env) do

    Enum.map(
      raw_registered_options,
      fn raw_registered_option ->
        RemapRegisteredOption.remap_raw_registered_option(raw_registered_option, env)
      end
    )

  end

  def remap_raw_interface_implementations(raw_interface_implementations, env) do

    Enum.map(
      raw_interface_implementations,
      fn raw_interface_implementation ->
        RemapInterfaceImplementation.remap_raw_interface_implementation(raw_interface_implementation, env)
      end
    )

  end

end