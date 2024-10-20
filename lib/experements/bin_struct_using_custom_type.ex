defmodule TestBinStructUsingCustomType do

  use BinStruct

  alias BinStruct.BuiltInCustomTypes.TerminatedBinary

  field :custom, { TerminatedBinary, termination: <<0, 0>> }

end
