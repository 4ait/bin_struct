defmodule TestBinStructUsingCustomType do

  use BinStruct

  alias BinStruct.BuiltIn.TerminatedBinary

  field :custom, { TerminatedBinary, termination: <<0, 0>> }

end
