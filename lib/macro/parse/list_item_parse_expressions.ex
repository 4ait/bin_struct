defmodule BinStruct.Macro.Parse.ListItemParseExpressions do

  alias BinStruct.Macro.IsPrimitiveType

  def parse_expression(item_type, item_binary_bind, options_bind) do

    case item_type do

      { :module, %{ module_type: :bin_struct, module: module } } ->

        quote do
          unquote(module).parse(unquote(item_binary_bind), unquote(options_bind))
        end

      {
        :module,
        %{
          module_type: :bin_struct_custom_type,
          module: module,
          custom_type_args: custom_type_args
        }
      } ->

        quote do
          unquote(module).parse(unquote(item_binary_bind), unquote(custom_type_args), unquote(options_bind))
        end

    end

  end

  def parse_exact_expression(item_type, item_binary_bind, options_bind) do

    is_item_of_primitive_type = IsPrimitiveType.is_primitive_type(item_type)

    case item_type do

      _item_type when is_item_of_primitive_type -> %{
          expr: item_binary_bind,
          is_infailable_of_primitive_type: true
        }

      { :module, %{ module_type: :bin_struct, module: module } } ->

        expr =
          quote do
            unquote(module).parse_exact(unquote(item_binary_bind), unquote(options_bind))
          end

        %{
          expr: expr,
          is_infailable_of_primitive_type: false
        }

      {
        :module,
        %{
          module_type: :bin_struct_custom_type,
          module: module,
          custom_type_args: custom_type_args
        }

      } ->

        expr =
          quote do
            unquote(module).parse_exact(unquote(item_binary_bind), unquote(custom_type_args), unquote(options_bind))
          end

        %{
          expr: expr,
          is_infailable_of_primitive_type: false
        }

    end




  end

end
