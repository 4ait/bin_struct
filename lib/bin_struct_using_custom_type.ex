defmodule TestBinStructUsingCustomType do

  use BinStruct

  field :custom, TestCustomType, custom_type_args: %{}

end
