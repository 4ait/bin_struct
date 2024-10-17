defmodule BinStruct.Macro.Preprocess.RemapAsn1 do

  def remap_asn1({:asn1, asn1_info_ast}, _opts, _env) do

    {:%{}, _meta, [module: asn1_module, type: asn1_type]} = asn1_info_ast

    asn1_info = %{
      module: asn1_module,
      type: asn1_type
    }

    { :asn1, asn1_info }

  end

end