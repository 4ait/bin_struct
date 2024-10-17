defmodule BinStruct.Macro.Parse.KnownSizeListOfStaticEncoder do

  alias BinStruct.Macro.Parse.KnownSizeTypeEncoder

  def encode_known_size_list_of_as_static_expr(%{
    length: _length,
    item_size: _item_size,
    count: _count
  } = bounds, access_field, item_type, opts, context) do

    { binary_match_expression, chunks_access }  =
      binary_match_pattern_for_known_size_list_of(bounds)


    bind_item = { :item, [], __MODULE__ }

    quote do

      unquote(binary_match_expression) = unquote(access_field)

      Enum.map(
        [ unquote_splicing(chunks_access) ],
        fn unquote(bind_item) ->

          unquote(
            KnownSizeTypeEncoder.encode_known_size_type(bind_item, item_type, opts, context)
          )

        end
      )

    end

  end

  defp chunk_access(chunk_index) do
    { String.to_atom("chunk_#{chunk_index}"), [], __MODULE__ }
  end

  defp list_of_chunk_pattern(chunk_index, chunk_size) do

    chunk_access = chunk_access(chunk_index)

    quote do
      unquote(chunk_access)::bytes-(unquote(chunk_size))
    end

  end

  defp binary_match_pattern_for_known_size_list_of(
         %{
           length: _length,
           item_size: item_size,
           count: count
         } = _bounds
       ) do

    chunks_access =
      Enum.map(
        1..count,
        fn chunk_index ->
          chunk_access(chunk_index)
        end
      )

    chunks =
      Enum.map(
        1..count,
        fn chunk_index ->
          list_of_chunk_pattern(chunk_index, item_size)
        end
      )

    binary_match_expression =
      quote do
        <<unquote_splicing(chunks)>>
      end

    { binary_match_expression, chunks_access }

  end


end