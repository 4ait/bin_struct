defmodule Exp do

  defmodule Item do
    use BinStruct

    alias BinStruct.BuiltIn.TerminatedBinary

    field :binary, { TerminatedBinary, termination: <<0>> }
  end

  defmodule StructWithItems do

    use BinStruct

    register_callback &take_while_by/1, items: :field

    field :items, { :list_of, Item }, take_while_by: &take_while_by/1

    defp take_while_by(items) do

      [ recent | _previous ] = items

      case recent.binary do
        <<4, 5, 6>> -> :halt
        _ -> :cont
      end

    end

  end

end

