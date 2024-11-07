defmodule BinStruct.Macro.Structs.RegisteredCallbackOptionArgument do

  alias BinStruct.Macro.Structs.RegisteredCallbackOptionArgument
  alias BinStruct.Macro.Structs.RegisteredOption

  @type t :: %RegisteredCallbackOptionArgument{
                registered_option: RegisteredOption.t()
             }

  defstruct [
    :registered_option
  ]

end