defmodule BinaryValuesBench do

  def benchmark() do

    # Simulating different binary data that could be received from the network
    inputs = %{
      "large binary" =>
        Enum.reduce(
          1..1000,
          <<>>,
          fn number, acc ->
            acc <> <<number::16-big-unsigned>>
          end
        )
    }

    Benchee.run(
      %{
        "parse, decode, new struct, and dump BinStructWithPrimitiveItemList" => (fn bin ->
          { :ok, parsed_struct, _rest } = BinStructWithPrimitiveItemList.parse(bin)



        end),

        "parse, decode, new struct, and dump BinStructWithStructItemList" => (fn bin ->
            { :ok, parsed_struct, _rest } = BinStructWithStructItemList.parse(bin)

                                                                              end),

        "parse, decode, new struct, and dump BinStructWithStructItemDynamicCallbackList" => (fn bin ->
          { :ok, parsed_struct, _rest } = BinStructWithStructItemDynamicCallbackList.parse(bin)

                                                                                             end),

      },
      inputs: inputs
    )
  end

end

BinaryValuesBench.benchmark()