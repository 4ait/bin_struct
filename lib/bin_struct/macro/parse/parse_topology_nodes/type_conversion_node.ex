defmodule BinStruct.Macro.Parse.ParseTopologyNodes.TypeConversionNode do

  @moduledoc false

  alias BinStruct.Macro.Parse.ParseTopologyNodes.TypeConversionNode

  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField

  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionUnspecified
  alias BinStruct.TypeConversion.TypeConversionBinary

  @type t :: %TypeConversionNode {
               subject:  Field.t() | VirtualField.t(),
               type_conversion: TypeConversionManaged |
                                TypeConversionUnmanaged |
                                TypeConversionUnspecified |
                                TypeConversionBinary
             }

  defstruct [
    :subject,
    :type_conversion
  ]


end
