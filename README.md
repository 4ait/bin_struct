# BinStruct

**BinStruct** is a library that provides a rich set of tools for parsing and encoding binaries.

The goal is to write declarations that are **readable now and will remain readable for years**. Your code will closely resemble a page from protocol documentation, ensuring clarity and maintainability.

This library is particularly beneficial for use cases that require **bidirectional data flow**.

## Installation

To get started, add `BinStruct` to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:bin_struct, "~> 0.2"}
  ]
end
```

## Getting Started

### Explore Examples

Start by exploring the examples folder. Run the following command to see an example in action:

```sh
mix run examples/png.exs
```

### Reference Documentation

- [BinStruct Module Documentation](https://hexdocs.pm/bin_struct/BinStruct.html)

#### Type-Specific Docs

- [StaticValue](https://hexdocs.pm/bin_struct/BinStruct.Types.StaticValue.html)
- [Binary](https://hexdocs.pm/bin_struct/BinStruct.Types.Binary.html)
- [Enum](https://hexdocs.pm/bin_struct/BinStruct.Types.Enum.html)
- [Flags](https://hexdocs.pm/bin_struct/BinStruct.Types.Flags.html)
- [List](https://hexdocs.pm/bin_struct/BinStruct.Types.ListOf.html)
- [Variant](https://hexdocs.pm/bin_struct/BinStruct.Types.VariantOf.html)

### Explore Tests

For further insights, check out the `test/` folder, where you can explore the library’s future functionality through tests.

## View generated code

there is module_code/0 function for any module with applied use macro to (BinStruct, BinStructCustomType or BinStructOptionsInterface)
which will show for you all generated code.

## Configuration

You can configure `BinStruct` by adding the following to your `config.exs` file:

```elixir
config :bin_struct,
  define_receive_send_tcp: false, #default false
  define_receive_send_tls: false, #default false
  enable_log_tcp: true, #default true
  enable_log_tls: true #default true
```

### Notes on TLS

- TLS functionality is implemented using the `:ssl` application.
- If you wish to use TLS, make sure to either **disable it** or add `:ssl` to the list of `extra_applications`:

  ```elixir
  def application do
    [
      extra_applications: [:ssl]
    ]
  end
  ```

## Additional Documentation

Comprehensive documentation is available online:  
[BinStruct Docs](https://hexdocs.pm/bin_struct)
