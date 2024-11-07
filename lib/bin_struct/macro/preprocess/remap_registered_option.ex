defmodule BinStruct.Macro.Preprocess.RemapRegisteredOption do

  alias BinStruct.Macro.Structs.RegisteredOption

  def remap_raw_registered_option(raw_registered_option, env) do

    { name, parameters } = raw_registered_option

    %RegisteredOption{
      name: name,
      interface: env.module,
      parameters: parameters
    }

  end


end