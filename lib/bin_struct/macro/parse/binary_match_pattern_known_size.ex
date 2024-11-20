defmodule BinStruct.Macro.Parse.BinaryMatchPatternKnownSize do

  @moduledoc false

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.FieldSize
  alias BinStruct.Macro.Bind

  def binary_match_pattern_for_known_size_field(field, context) do

    %Field{ name: name, type: type } = field

    binary_value_access = Bind.bind_binary_value(name, context)

    case type do

      { :static_value, %{ value: value } } ->

        quote do
          unquote(value)
        end

      _ ->

        field_size_bits = FieldSize.field_size_bits(field)

        case Integer.mod(field_size_bits, 8) do

          0 ->

            field_size_bytes = Integer.floor_div(field_size_bits, 8)

            quote do
              unquote(binary_value_access)::(unquote(field_size_bytes)-bytes)
            end

          _ ->

            quote  do
              unquote(binary_value_access)::(unquote(field_size_bits)-bits)
            end

        end

    end


  end


end