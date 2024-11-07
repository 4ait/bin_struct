defmodule BinStruct.Macro.Parse.Result do

  alias BinStruct.Macro.Bind

  alias BinStruct.Macro.Structs.Field

  def return_ok_tuple(fields, context) do

    rest_bind = { :rest, [], context }
    options_bind = { :options, [], context }

    tuple_fields =
      Enum.map(
        fields,
        fn field ->

          %Field{ name: name } = field

          Bind.bind_unmanaged_value(name, context)

        end
      )

    quote do
      { :ok, unquote_splicing(tuple_fields), unquote(rest_bind), unquote(options_bind) }
    end

  end

end