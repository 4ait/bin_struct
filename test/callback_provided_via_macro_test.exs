defmodule BinStructTest.CallbackProvidedViaMacroTest do

  use ExUnit.Case

  defmodule MacroForStruct do


    defmacro create_callback() do

      quote do

        register_callback &callback_name/0

        defp callback_name(), do: true

      end

    end

    def create_callback_ref() do
      {:&, [], [{:/, [], [{:callback_name, [], Elixir}, 0]}]}
    end

  end


  defmodule Struct do

    use BinStruct

    import MacroForStruct

    create_callback()

    field :a, :binary, length: 1, optional_by: create_callback_ref()

  end


  test "struct with binary values works" do

    Struct.new(a: 1)

  end

end

