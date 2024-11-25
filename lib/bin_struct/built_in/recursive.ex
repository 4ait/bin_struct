defmodule BinStruct.BuiltIn.Recursive do

  @moduledoc """

  A custom type for handling recursive structures within `BinStruct`.

  ## Overview

  The `Recursive` custom type is designed to facilitate parsing, size computation, and binary serialization
  of nested or recursive structures in a way that allows the library to manage recursion efficiently.

  Instead of relying on the library to directly introspect recursive types during compile-time analysis,
  this module enables wrapping a recursive type with a custom definition. By doing so, it delegates
  the responsibility of compile-time introspection to the custom type itself. This allows for more
  precise control over how the recursive type is handled and provides an avenue for customization
  in the future (though such customization is not yet implemented).

  ## Example Usage

  Instead of declaring a recursive type directly:

  ```elixir
  field :sequence, Sequence
  ```

  Wrap the recursive type with Recursive:

  ```elixir
  field :sequence, {Recursive, module: Sequence}
  ```

  """

  use BinStructCustomType

  def init_args(custom_type_args) do

    args = %{
      module: custom_type_args[:module]
    }

    case args do
      %{ module: module } when is_atom(module) -> { :ok, args }
      _ -> { :error, ":module argument required but not provided" }
    end

  end

  def parse_returning_options(bin, custom_type_args, opts) do

    %{
      module: module
    } = custom_type_args

    module.parse_returning_options(bin, opts)

  end

  def size(data, custom_type_args) do

    %{
      module: module
    } = custom_type_args

    module.size(data)

  end

  def dump_binary(data, custom_type_args) do

    %{
      module: module
    } = custom_type_args

    module.dump_binary(data)

  end

  def known_total_size_bytes(_custom_type_args), do:  :unknown
  def from_unmanaged_to_managed(unmanaged, _custom_type_args), do: unmanaged
  def from_managed_to_unmanaged(managed, _custom_type_args), do: managed

end
