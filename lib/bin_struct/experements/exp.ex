defmodule IENDChunk do

  use BinStruct

  alias BinStruct.PrimitiveEncoder

  field :length, { :static, PrimitiveEncoder.uint32_be(0) }

  field :type, "IEND"

  field :data, <<>>

  field :crc, :uint32_be

end