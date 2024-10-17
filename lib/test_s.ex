defmodule StructWithItems1 do

  use BinStruct

  field :boolean_items, { :list_of, :bool }, count: 3
  field :integer_items, { :list_of, :uint8 }, count: 3

end


