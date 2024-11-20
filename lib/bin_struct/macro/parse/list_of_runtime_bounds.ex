defmodule BinStruct.Macro.Parse.ListOfRuntimeBounds do

  @moduledoc false

  alias BinStruct.Macro.Parse.ListOfBoundaryConstraintFunctionCall

  def get_runtime_bounds(%{
    any_length: any_length,
    any_count: any_count,
    any_item_size: any_item_size,
  } = _bounds,
        registered_callbacks_map,
        context
      ) do
    get_runtime_bounds_all(any_length, any_count, any_item_size, registered_callbacks_map, context)
  end

  def get_runtime_bounds(%{
    any_count: any_count,
    any_item_size: any_item_size
  } = _bounds, registered_callbacks_map, context) do
    get_runtime_bounds_by_count_and_item_size(any_count, any_item_size, registered_callbacks_map, context)
  end

  def get_runtime_bounds(%{
    any_length: any_length,
    any_item_size: any_item_size
  } = _bounds, registered_callbacks_map, context) do
    get_runtime_bounds_by_length_and_item_size(any_length, any_item_size, registered_callbacks_map, context)
  end


  def get_runtime_bounds(%{
    any_length: any_length,
    any_count: any_count,
  } = _bounds, registered_callbacks_map, context) do
    get_runtime_bounds_by_length_and_count(any_length, any_count, registered_callbacks_map, context)
  end


  defp get_runtime_bounds_all(
        any_length,
        any_count,
        any_item_size,
        registered_callbacks_map,
        context
      ) do

    quote do

      length = unquote(ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(any_length, registered_callbacks_map, context))
      count = unquote(ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(any_count, registered_callbacks_map, context))
      item_size = unquote(ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(any_item_size, registered_callbacks_map, context))
      
      %{
        length: length,
        count: count,
        item_size: item_size
      }

    end

  end

  defp get_runtime_bounds_by_count_and_item_size(
         any_count,
         any_item_size,
         registered_callbacks_map,
         context
      ) do

    quote do

      count = unquote(ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(any_count, registered_callbacks_map,  context))
      item_size = unquote(ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(any_item_size, registered_callbacks_map, context))
      
      %{
        length: count * item_size,
        count: count,
        item_size: item_size,
      }

    end

  end

  defp get_runtime_bounds_by_length_and_item_size(
         any_length,
         any_item_size,
         registered_callbacks_map,
         context
      ) do

    quote do

      length = unquote(ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(any_length, registered_callbacks_map, context))
      item_size = unquote(ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(any_item_size, registered_callbacks_map, context))

      %{
        length: length,
        count: Integer.floor_div(length, item_size),
        item_size: item_size,
      }

    end

  end

  defp get_runtime_bounds_by_length_and_count(
        any_length,
        any_count,
        registered_callbacks_map,
        context
      ) do


    quote do

      length = unquote(ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(any_length, registered_callbacks_map, context))
      count = unquote(ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(any_count, registered_callbacks_map, context))

      %{
        length: length,
        count: count,
        item_size: Integer.floor_div(length, count)
      }

    end

  end

end