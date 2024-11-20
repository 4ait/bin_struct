defmodule BinStruct.Docs.BinStructCustomType do

  @moduledoc """

  BinStructCustomType is user defined type when you need most flexibility.

  Such custom type can be used in place you would use BinStruct.

  The only currently limitation it can't be used directly inside variant_of (variant_of dispatching relays on elixir struct).

  Required functions to be defined by custom type:

      either parse_returning_options/3 or parse_exact_returning_options/3
      size/2
      known_total_size_bytes/2
      dump_binary/2
      from_unmanaged_to_managed/2
      from_managed_to_unmanaged/2

  Optional functions to be defined by custom type:
      init_args/1

  Here’s an example:

  ## Basic Example

    ```

      defmodule SimpleCustomTypeTwoBytesLong do

        use BinStructCustomType

        def parse_returning_options(bin, _custom_type_args, opts) do

          case bin do
            <<data::2-bytes, rest::binary>> -> { :ok, data, rest, opts }
            _ -> :not_enough_bytes
          end

        end

        def size(_data, _custom_type_args), do: 2
        def known_total_size_bytes(_custom_type_args), do: 2
        def dump_binary(data, _custom_type_args), do: data
        def from_unmanaged_to_managed(unmanaged, _custom_type_args), do: unmanaged
        def from_managed_to_unmanaged(managed, _custom_type_args), do: managed

      end

    ```

  """

end
