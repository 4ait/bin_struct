defmodule StructWithVirtualFields do

  #use BinStruct

  #field :number, :uint8


end


defmodule Some.ModuleA.A do

end


defmodule Some.ModuleB.A do

end


defmodule TestMod do


  alias Some.ModuleA
  alias Some.ModuleB

  def test_case(mod) do

    case mod do
      ModuleA.A -> 1
      ModuleB.A -> 2
    end

  end

end