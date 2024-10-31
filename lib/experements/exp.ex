defmodule Item do
  use BinStruct

  register_callback &length_by/0

  field :binary, :binary, length_by: &length_by/0

  defp length_by(), do: 1

end

defmodule StructWithItems do

  use BinStruct

  register_callback &take_while_by/1, items: :field

  field :items, { :list_of, Item }, take_while_by: &take_while_by/1

  defp take_while_by(items) do

    [ recent | _previous ] = items

    %{
      binary: binary
    } = Item.decode(recent)

    case binary do
      <<3>> -> :halt
      _ -> :cont
    end

  end

end