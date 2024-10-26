
defmodule TrueImpl do

  use BinStruct

  field :number, :uint8

end


defmodule StructWithVirtualFields do

  use BinStruct

  alias BinStruct.TypeConversion.TypeConversionBinary

  register_callback &data_for_actual_impl/1, nested_binary: :field

  register_callback &nested_binary_builder/1, actual_implementation: %{ type: :field, type_conversion: TypeConversionBinary }

  virtual :actual_implementation, TrueImpl,
          read_by: &data_for_actual_impl/1

  field :nested_binary, :binary,
        length: 1,
        builder: &nested_binary_builder/1

  defp data_for_actual_impl(nested_binary) do
    { :ok, true_impl } = TrueImpl.parse_exact(nested_binary)
    true_impl
  end

 defp nested_binary_builder(true_impl_bin), do: true_impl_bin

end

defmodule TestApi do

  def call() do

    StructWithVirtualFields.new(actual_implementation: TrueImpl.new(number: 1))

  end

end

