defmodule ItemStruct do

  use BinStruct

  field :value, :uint8

end

defmodule StructWithItems do

  use BinStruct

  field :items, { :list_of, ItemStruct }, count: 3

end