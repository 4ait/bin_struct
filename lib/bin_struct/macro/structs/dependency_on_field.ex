defmodule BinStruct.Macro.Structs.DependencyOnField do

  @moduledoc false

  alias BinStruct.Macro.Structs.DependencyOnField
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Structs.VirtualField
  alias BinStruct.Macro.Structs.TypeConversionManaged
  alias BinStruct.Macro.Structs.TypeConversionUnmanaged

  @type t :: %DependencyOnField {
               field: Field.t() | VirtualField.t(),
               type_conversion: TypeConversionManaged.t() | TypeConversionUnmanaged.t()
             }

  defstruct [
    :field,
    :type_conversion
  ]


end
