defmodule Item do
  use BinStruct

  alias BinStruct.BuiltIn.TerminatedBinary

  field :binary, { TerminatedBinary, termination: <<0>> }
end

defmodule StructWithItems do

  use BinStruct
  field :items, { :list_of, Item }

end