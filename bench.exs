defmodule BinaryValuesBinStruct do

  use BinStruct

  alias BinStruct.BuiltIn.TerminatedBinary

  field :binary_fixed_lenght, :binary, length: 3
  field :binary_terminated, { TerminatedBinary, termination: <<0, 0>> }

end

defmodule BinaryValuesBench do

  def benchmark() do

    # Simulating different binary data that could be received from the network
    inputs = %{
      "small binary" => "123" <> <<0, 0>>,
      "medium binary" => String.duplicate("a", 100) <> <<0, 0>> ,
      "large binary" => String.duplicate("b", 1000) <> <<0, 0>>
    }

    Benchee.run(
      %{
        "parse, decode, new struct, and dump" => fn bin ->
          # 1. Parse the received binary
          { :ok, parsed_struct, _rest } = BinaryValuesBinStruct.parse(bin)

          # 2. Decode the parsed struct
          decoded_values = BinaryValuesBinStruct.decode(parsed_struct)

          # 3. Create a new struct from the decoded values
          new_struct = BinaryValuesBinStruct.new(decoded_values)

          # 4. Dump the new struct back to binary (simulating sending)
          BinaryValuesBinStruct.dump_binary(new_struct)

        end
      },
      inputs: inputs
    )
  end

end

BinaryValuesBench.benchmark()