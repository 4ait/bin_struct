defmodule BinStructTest.ModuleTests.ModuleTest do

  use ExUnit.Case

  defmodule Child do

    use BinStruct

    field :binary, <<3, 2, 1>>

  end

  defmodule Parent do

    use BinStruct

    field :child, Child

  end


  test "struct child works" do

    child = Child.new()
    parent = Parent.new(child: child)

    dump = Parent.dump_binary(parent)

    { :ok, parsed_struct, _rest } = Parent.parse(dump)

    values = Parent.decode(parsed_struct)

    %{
      child: ^child,
    } = values

  end

end

