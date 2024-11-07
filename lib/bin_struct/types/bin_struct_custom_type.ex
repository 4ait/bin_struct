defmodule BinStruct.Types.BinStructCustomType do

  @moduledoc """

  BinStructCustomType is user defined type when you need most flexibility.

  Such custom type can be used in place you would use BinStruct.

  The only currently limitation it can't be used directly inside variant_of (variant_of dispatching relays on elixir struct).


  Required functions to be defined by custom type:

      size/2


  Here’s an example:

  ## Basic Example

    ```

      defmodule SimpleCustomType do

        use BinStructCustomType

        def parse_returning_options(bin, _custom_type_args, opts) do

          case bin do
            <<data::10-bytes, rest::binary>> -> { :ok, data, rest, opts }
            _ -> :not_enough_bytes
          end

        end

        def size(_data, _custom_type_args), do: 10
        def dump_binary(data, _custom_type_args), do: data
        def known_total_size_bytes(_custom_type_args), do: 10

      end

    ```

  """

end
