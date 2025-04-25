defmodule TestSingleStruct do

  use BinStruct

  field :a, :uint8
  field :b, :uint8

  compile_decode_single :decode_a, :a

end