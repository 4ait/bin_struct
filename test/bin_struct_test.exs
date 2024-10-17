defmodule BinStructTest do
  use ExUnit.Case
  doctest BinStruct

  test "greets the world" do
    assert BinStruct.hello() == :world
  end
end
