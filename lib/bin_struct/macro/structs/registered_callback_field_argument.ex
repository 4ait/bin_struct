defmodule BinStruct.Macro.Structs.RegisteredCallbackFieldArgument do

  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField

  alias BinStruct.TypeConversion.TypeConversionManaged
  alias BinStruct.TypeConversion.TypeConversionUnmanaged
  alias BinStruct.TypeConversion.TypeConversionBinary
  alias BinStruct.TypeConversion.TypeConversionUnspecified

  @type t :: %RegisteredCallbackFieldArgument{
                field: Field.t() | VirtualField.t(),
                type_conversion:
                  TypeConversionManaged |
                  TypeConversionUnmanaged |
                  TypeConversionBinary |
                  TypeConversionUnspecified
             }


  defstruct [
    :field,
    :type_conversion
  ]


end
