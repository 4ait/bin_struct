defmodule BinStruct.Types.ListOf do

  @moduledoc """

  There is 3 types of list_of supported

  ## With compile time known bounds

  BinStruct needs to know at least 2 params out of length (size in bytes), item size (in bytes) or items count

  Item size will be inferred if possible in case its primitive with known size or module with known_total_size_bytes

  ```
      defmodule ListStruct do
        use BinStruct
        field :items, { :list_of, :uint32_be }, count: 2
      end
  ```

  ```
      defmodule ListStruct do
        use BinStruct
        field :items, { :list_of, :uint32_be }, length: 8
      end
  ```


  ## With runtime known bounds

  Same as with compile time known bounds, but any of 2 bounds could be given via registered callback

  Overhead of dynamic bounds comparing to known in compile time almost negligible

  ```
      defmodule ListStruct do
        use BinStruct

        register_callback &count/0

        field :items, { :list_of, :uint32_be }, count_by: &count/0

        defp count(), do: 2

      end
  ```

  ## With only one criteria known

  Struct below has only one criteria (item size)

  It still can be parsed, but such struct called "not terminated" and only parse_exact/2 function will be generated

  So in case to parse this struct caller (manually called by user or nested in another BinStruct) should provide finite input.

    ```
      defmodule ListStruct do
        use BinStruct
        field :items, { :list_of, :uint32_be }
      end
  ```

  ## Without any bounds criteria


      It's still possible to parse struct even then we are not know about its size anything, for example

    ```

      defmodule Item do
        use BinStruct

        register_callback &len_by/1, len: :field

        field :len, :uint16_be
        field :value, :binary, length_by: &len_by/1

        defp len_by(len), do: len

      end

      defmodule ListStruct do
        use BinStruct
        field :items, Item
      end

    ```

      You can parse as much items such items as it in finite bytes source using parse_exact/2


  ## With manual selection upon dynamic criteria


      We can restrict example from "Without any bounds criteria" even future using take_while_by callback to any dynamic criteria

    ```

      defmodule Item do
        use BinStruct

        register_callback &len_by/1, len: :field

        field :len, :uint16_be
        field :value, :binary, length_by: &len_by/1

        defp len_by(len), do: len

      end

      defmodule ListStruct do
        use BinStruct

        register_callback &take_while_by/1, items: :field

        field :items, Item, take_while_by: &take_while_by/1


        defp take_while_by(items) do

          [ current_item | previous_items ] = items

          case Item.decode(current_item) do
            %{ value: "magic value to stop" } -> :halt
            _ -> :cont
          end

        end

      end

    ```


    Now struct can be parsed from infinity bytestream (parse/2 function will be available)

  Notice callback takes field itself to which he applied,
    which is normally not possible and its unique behaviour of take_while_by callback.

    Also notice items are reversed, this is expected to elixir/erlang linked list implementation nature as it more performant
    to both produce and to read.

    Type conversions are specially optimized to this callback,
    type conversion for any item will acquire only once for each item of each type conversion requested


  ## Future exploring

      Most detailed behaviours can be found in test modules in BinStructTest.ListOfTests.*

  """

end
