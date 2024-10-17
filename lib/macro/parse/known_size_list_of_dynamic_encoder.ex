defmodule BinStruct.Macro.Parse.KnownSizeListOfDynamicEncoder do

  alias BinStruct.Macro.Parse.KnownSizeTypeEncoder

  def encode_known_size_list_of_as_dynamic_expr(%{
    length: _length,
    item_size: item_size,
    count: count
  } = _bounds, access_field, item_type, opts, context) do

    bind_item = { :item, [], __MODULE__ }
    options_access = { :options, [], context }

    case item_type do

      { :module, _module_info }  ->

        { :bin_struct_parse_exact_result, item_encode_expr } = KnownSizeTypeEncoder.encode_known_size_type(bind_item, item_type, opts, context)

        quote do

          { "", chunks } =
            Enum.reduce(
              1..unquote(count),
              { unquote(access_field), [] },
              fn _index, { bin, chunks } ->

                <<chunk::unquote(item_size)-bytes, rest::binary>> = bin

                { rest, [ chunk | chunks ] }

              end
            )

          chunks = Enum.reverse(chunks)

          result =
            Enum.reduce_while(chunks, { :ok, [], unquote(options_access) }, fn item, { :ok, curr_items, curr_options } ->

              unquote(options_access) = curr_options

              case unquote(item_encode_expr) do

                { :ok, encoded_item, new_options } ->

                  new_items = [ encoded_item | curr_items ]

                  { :cont, { :ok, new_items, new_options } }

                bad_result -> { :halt, bad_result }

              end

            end)


          case result do
            { :ok, items, options } ->  { :ok, Enum.reverse(items), options }
            bad_result -> bad_result
          end

        end

      _ ->

        quote do

          items =
            for << unquote(bind_item)::bytes-(unquote(item_size)) <- unquote(access_field) >> do

              unquote(
                KnownSizeTypeEncoder.encode_known_size_type(bind_item, item_type, opts, context) || bind_item
              )

            end

          { :ok, items, unquote(options_access) }

        end

    end


  end


end