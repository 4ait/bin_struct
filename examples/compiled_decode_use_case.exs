#we will optimize hot path with decode use cases

#Problem: we need only length in some hot path and only version in another
#This is particular usefully for complex structures with many chain dependency through virtual field
#Every use case compiling using it's own graph and producing only required values for best perfomance

defmodule Header do

  use BinStruct

  field :version, {
    :enum,
    %{
      type: :uint8,
      values: [
        { 1, :protocol_ver_1 },
        { 2, :protocol_ver_2 }
      ]
    }
  }

  field :length, :uint32_be

  #Solving without compiled decode_only function

  compile_decode_only :decode_only_version, [ :version ]
  compile_decode_only :decode_only_length, [ :length ]

  #or without name with pattern only
  compile_decode_only [ :version, :length ]


end

#Usage

struct = Header.new(version: :protocol_ver_2, length: 100)

%{ version: :protocol_ver_2 } = Header.decode_only_version(struct)

%{ length: 100 } = Header.decode_only_length(struct)

#in case we are not compiled this pattern for unnamed decode_only calls there will be fallback to decode all + filter and warning
#with instructions how to compile it properly

%{
  version: :protocol_ver_2,
  length: 100
} = Header.decode_only(struct, [ :version, :length ])





