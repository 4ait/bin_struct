defmodule TestBinStructUsingCustomType do

  use BinStruct

  alias BinStruct.BuiltIn.TerminatedBinary

  register_callback &check_if_starting_with_pattern/1,
                    custom: :field

  field :custom, { TerminatedBinary, termination: <<0, 0>> },
        validate_by: &check_if_starting_with_pattern/1

  defp check_if_starting_with_pattern(binary) do
    String.starts_with?(binary, "Pattern:")
  end

end
