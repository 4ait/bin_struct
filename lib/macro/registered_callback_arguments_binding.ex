defmodule BinStruct.Macro.RegisteredCallbackArgumentsBinding do

  alias BinStruct.Macro.Structs.RegisteredCallback
  alias BinStruct.Macro.Structs.RegisteredOption
  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackItemArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.Structs.RegisteredCallbackNewArgument
  alias BinStruct.Macro.Encoder
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.IsOptionalField

  def registered_callback_arguments_bindings(
        %RegisteredCallback{ arguments: arguments },
        context
      ) do

    Enum.map(
      arguments,
      fn argument ->

        case argument do

          %RegisteredCallbackFieldArgument{} = argument ->

            %RegisteredCallbackFieldArgument{ field: field, options: options } = argument

            %Field { name: name, type: type } = field

            bind = { BinStruct.Macro.Bind.bind_value_name(name), [], context }

            encode_expr = Encoder.decode_bin_struct_field_to_term(type, bind)

            case options[:encode] do
              :raw -> bind
              _ ->

                if IsOptionalField.is_optional_field(field) do

                    quote do

                      case unquote(bind) do
                        nil -> nil
                        unquote(bind) -> unquote(encode_expr)
                      end

                    end

                else
                  encode_expr
                end

            end

          %RegisteredCallbackNewArgument{} = new_argument ->

            %RegisteredCallbackNewArgument{ field: field, options: options } = new_argument

            { name, type, opts } =
              case field do
                %Field { name: name, type: type, opts: opts } ->  { name, type, opts }
                %VirtualField { name: name, type: type, opts: opts } -> { name, type, opts }
              end

            bind = { BinStruct.Macro.Bind.bind_value_name(name), [], context }


            case options[:encode] do

              :binary ->

                is_optional = BinStruct.Macro.IsOptionalField.is_optional_field(field)
                expr = BinStruct.Macro.DumpBinaryFunction.encode_type_for_dump(bind, type, opts, is_optional)
                Encoder.encode_term_to_bin_struct_field(type, expr)

              :raw -> Encoder.encode_term_to_bin_struct_field(type, bind)

              _ -> bind

            end

          %RegisteredCallbackItemArgument{item_of_field: item_of_field} = argument ->

            %RegisteredCallbackItemArgument{ options: options } = argument

            %Field { name: item_of_field_name, type: item_of_field_type } = item_of_field

            case item_of_field_type do

              { :list_of, %{ item_type: item_type } = _list_of_info } ->

                value_bind_name = BinStruct.Macro.Bind.bind_value_name(item_of_field_name)

                bind_item = { BinStruct.Macro.Bind.bind_item_of_value_name(value_bind_name), [], context }

                case options[:encode] do
                  :raw -> bind_item
                  _ -> Encoder.decode_bin_struct_field_to_term(item_type, bind_item)
                end

            end


          %RegisteredCallbackOptionArgument{
            registered_option: %RegisteredOption {
              interface: interface,
              name: name
            }
          } -> { BinStruct.Macro.Bind.bind_option_name(interface, name), [], context }


        end

      end
    )

  end



end