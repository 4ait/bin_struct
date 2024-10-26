defmodule StructWithPrimitiveItems do

  use BinStruct

  field :items, { :list_of, :uint16_be }

end