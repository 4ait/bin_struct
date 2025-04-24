defmodule BinStruct.Macro.Preprocess.RemapInterfaceImplementation do

  @moduledoc false

  alias BinStruct.Macro.Structs.InterfaceImplementation
  alias BinStruct.Macro.Preprocess.RemapCallback

  def remap_raw_interface_implementation(raw_interface_implementation, env) do

    { interface, raw_callback, raw_options } = raw_interface_implementation

    callback = RemapCallback.remap_callback(raw_callback, env)

    %InterfaceImplementation{
      interface: interface,
      callback: callback,
      force_call_before_parse_field_name: raw_options[:for]
    }

  end


end