defmodule BinStruct.Macro.Preprocess.RemapCallbackOptions do

  alias BinStruct.Macro.Preprocess.RemapCallback

  def remap_callback_options(opts, env) do

    opts
    |> Keyword.replace(
        :optional_by,
         RemapCallback.remap_callback(opts[:optional_by], env)
    )
    |> Keyword.replace(
        :length_by,
         RemapCallback.remap_callback(opts[:length_by], env)
      )
    |> Keyword.replace(
        :count_by,
         RemapCallback.remap_callback(opts[:count_by], env)
      )
    |> Keyword.replace(
        :item_size_by,
         RemapCallback.remap_callback(opts[:item_size_by], env)
      )
    |> Keyword.replace(
         :take_while_by,
         RemapCallback.remap_callback(opts[:take_while_by], env)
       )
    |> Keyword.replace(
        :validate_by,
         RemapCallback.remap_callback(opts[:validate_by], env)
      )
    |> Keyword.replace(
         :builder,
         RemapCallback.remap_callback(opts[:builder], env)
       )
    |> Keyword.replace(
         :read_by,
         RemapCallback.remap_callback(opts[:read_by], env)
       )
    |> Keyword.replace(
         :write_by,
         RemapCallback.remap_callback(opts[:write_by], env)
       )

  end

end