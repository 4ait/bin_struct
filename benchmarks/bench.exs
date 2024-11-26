defmodule BenchBinStructWithPrimitiveItemList do

  use BinStruct

  field :items, { :list_of, :uint32_be }, length: 1000

end

defmodule BenchBinStructWithDynamicPrimitiveItemList do

  use BinStruct

  register_callback &take_while_not_1000_items/1,
                    items: :field

  field :items, { :list_of, :uint32_be }, take_while_by: &take_while_not_1000_items/1

  defp take_while_not_1000_items([1000 | _prev]), do: :halt
  defp take_while_not_1000_items(_), do: :cont

end


defmodule BenchItem do

  use BinStruct

  field :value, :uint32_be

end



defmodule BenchBinStructWithStructDynamicItemList do

  use BinStruct

  register_callback &take_while_not_1000_items/1,
                    items: :field

  field :items, { :list_of, BenchItem }, take_while_by: &take_while_not_1000_items/1

  defp take_while_not_1000_items([head | _prev]) do

    %{ value: value } = BenchItem.decode(head)

    case value do
      1000 -> :halt
      _ -> :cont
    end

  end

end


defmodule BenchBinStructWithStructItemList do

  use BinStruct

  field :items, { :list_of, BenchItem }, length: 1000

end


defmodule BinaryValuesBench do

  def benchmark() do

    # Simulating different binary data that could be received from the network
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
        "parse, decode, new struct, and dump BinStructWithPrimitiveItemList" => (fn bin ->
          { :ok, parsed_struct, _rest } = BenchBinStructWithPrimitiveItemList.parse(bin)
        end),

        "parse, decode, new struct, and dump BinStructWithDynamicPrimitiveItemList" => (fn bin ->
           { :ok, parsed_struct, _rest } = BenchBinStructWithDynamicPrimitiveItemList.parse(bin)

        end),

        "parse, decode, new struct, and dump BinStructWithStructItemList" => (fn bin ->
            { :ok, parsed_struct, _rest } = BenchBinStructWithStructItemList.parse(bin)

                                                                              end),

        "parse, decode, new struct, and dump BinStructWithStructDynamicItemList" => (fn bin ->
          { :ok, parsed_struct, _rest } = BenchBinStructWithStructDynamicItemList.parse(bin)

                                                                                             end),

      },
      inputs: inputs
    )
  end

end

BinaryValuesBench.benchmark()