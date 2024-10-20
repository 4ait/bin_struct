defmodule TestBinStructUsingCustomType do

  use BinStruct

  field :custom, { TerminatedString,  %{ termination: <<0, 0>> } }

end
