defmodule BooleanValuesBinStruct do

  use BinStruct

  field :true_bool, :bool
  field :false_bool, :bool
  field :bool_16_bit, :bool, bits: 16

end