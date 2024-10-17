defmodule BinStruct.Macro.Parse.KnownSizeListOfDynamicEncoder do

  alias BinStruct.Macro.Parse.KnownSizeTypeEncoder

  def encode_known_size_list_of_as_dynamic_expr(%{
    length: _length,
    item_size: item_size,
    count: _count
  } = _bounds, access_field, item_type, opts, context) do

    bind_item = { :item, [], __MODULE__ }

    quote do

      for << unquote(bind_item)::bytes-(unquote(item_size)) <- unquote(access_field) >> do

        unquote(
          KnownSizeTypeEncoder.encode_known_size_type(bind_item, item_type, opts, context)
        )

      end

    end


  end


end