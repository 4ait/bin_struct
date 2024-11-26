defmodule BoundedCompileTime do

  use BinStruct

  field :items, { :list_of, :binary },
        length: 1000,
        item_size: 4

end

defmodule BoundedRuntime do

  use BinStruct

  register_callback &length_by/0

  field :items, { :list_of, :binary },
        length_by: &length_by/0,
        item_size: 4

  defp length_by(), do: 1000

end


defmodule BinaryValuesBench do

  def benchmark() do

    inputs = %{
      "large binary" =>
        Enum.reduce(
          1..1000,
          <<>>,
          fn number, acc ->
            acc <> <<number::32-big-unsigned>>
          end
        )
    }

    Benchee.run(
      %{

        "BoundedCompileTime" => fn bin ->
          { :ok, parsed_struct, _rest } = BoundedCompileTime.parse(bin)
        end,

        "BoundedRuntime" => fn bin ->
           { :ok, parsed_struct, _rest } = BoundedRuntime.parse(bin)
        end,


      },
      inputs: inputs
    )
  end

end

BinaryValuesBench.benchmark()