defmodule BinStructWithStaticValue2 do

  use BinStruct
  field :static_value, { :static, BinStructStaticValue2.uint32_be(1) }
end