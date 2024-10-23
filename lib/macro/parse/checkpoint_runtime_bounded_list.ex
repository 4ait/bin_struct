defmodule BinStruct.Macro.Parse.CheckpointRuntimeBoundedList do

  alias BinStruct.Macro.Parse.ListItemParseExpressions
  alias BinStruct.Macro.Parse.ListOfRuntimeBounds
  alias BinStruct.Macro.Parse.Validation
  alias BinStruct.Macro.Parse.DeconstructOptionsForField
  alias BinStruct.Macro.Parse.WrapWithOptionalBy
  alias BinStruct.Macro.Structs.Field


  def runtime_bounded_list_checkpoint(
         %{ type: :runtime_bounded } = list_of_info,
         %Field{} = field,
         function_name,
         dependencies_bindings,
         interface_implementations,
         registered_callbacks_map,
         _env
       ) do

    %{
      bounds: bounds,
      item_type: item_type
    } = list_of_info

    %Field{ opts: opts } = field

    optional_by = opts[:optional_by]

    runtime_bounds_expr = ListOfRuntimeBounds.get_runtime_bounds(bounds, registered_callbacks_map, __MODULE__)

    options_bind = { :options, [], __MODULE__ }
    item_binary_bind = { :item, [], __MODULE__ }
    initial_binary_access = { :bin, [], __MODULE__ }

    parse_expr = ListItemParseExpressions.parse_expression(item_type, item_binary_bind, options_bind)

    body =
      quote do

        %{
          length: length,
          count: _count,
          item_size: item_size,
        } = unquote(runtime_bounds_expr)

        if byte_size(unquote(initial_binary_access)) >= length do

          <<target_binary::size(length)-bytes, rest::binary>> = unquote(initial_binary_access)

          chunks =
            for << chunk::binary-size(item_size) <- unquote(initial_binary_access) >> do
              chunk
            end

          result =
            Enum.reduce_while(chunks, { :ok, [] }, fn unquote(item_binary_bind), acc ->

              { _, items } = acc

              case unquote(parse_expr) do

                { :ok, unmanaged_item } ->

                  new_items = [ unmanaged_item | items ]

                  { :cont, { :ok, new_items } }

                bad_result -> { :halt, bad_result }

              end

            end)


          case result do
            { :ok, items } ->  { :ok, Enum.reverse(items), rest, unquote(options_bind) }
            bad_result -> bad_result
          end

        else
          :not_enough_bytes
        end

      end


    wrong_data_binary_bind = { :binary_for_wrong_data, [], __MODULE__ }

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, wrong_data_binary_bind, __MODULE__)

    validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, body, __MODULE__)

    quote do

      defp unquote(function_name)(
             unquote(initial_binary_access),
             unquote_splicing(dependencies_bindings),
             options
           ) when is_binary(unquote(initial_binary_access)) do

        unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

        unquote(wrong_data_binary_bind) = unquote(initial_binary_access)

        unquote(
          WrapWithOptionalBy.maybe_wrap_with_optional_by(validate_and_return_clause, optional_by, initial_binary_access, registered_callbacks_map, __MODULE__)
        )
      end

    end

  end

end
