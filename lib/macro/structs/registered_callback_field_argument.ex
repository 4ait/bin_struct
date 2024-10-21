defmodule BinStruct.Macro.Structs.RegisteredCallbackFieldArgument do

  alias BinStruct.Macro.Structs.RegisteredCallbackFieldArgument
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.Structs.TypeConversionManaged
  alias BinStruct.Macro.Structs.TypeConversionUnmanaged
  alias BinStruct.Macro.Structs.TypeConversionUnspecified

  @type t :: %RegisteredCallbackFieldArgument{
                field: Field.t() | VirtualField.t(),
                type_conversion:
                  TypeConversionManaged.t() |
                  TypeConversionUnmanaged.t() |
                  TypeConversionUnspecified.t()
             }


  defstruct [
    :field,
    :type_conversion
  ]


end
