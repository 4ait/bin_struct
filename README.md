# BinStruct

BinStruct is a library which provides you rich set of tools for manipulating with binaries.
The goal is write declarations, which is readable now and will be readable even after years.
You can expect your actual code be more like page from protocol documentation.

Most benefit you will get if bidirectional data flow is what you need.

## Installation

```elixir
def deps do
  [
    {:bin_struct, "~> 0.2.7"}
  ]
end
```

## Getting Started 
I suggest you to start with examples folder.
You can run 
```
    mix run examples/png.exs
```

Next is docs in BinStruct module https://hexdocs.pm/bin_struct/BinStruct.html

And docs for types

StaticValue https://hexdocs.pm/bin_struct/BinStruct.Types.StaticValue.html

Binary https://hexdocs.pm/bin_struct/BinStruct.Types.Binary.html

Enum https://hexdocs.pm/bin_struct/BinStruct.Types.Enum.html

Flags https://hexdocs.pm/bin_struct/BinStruct.Types.Enum.html

List https://hexdocs.pm/bin_struct/BinStruct.Types.ListOf.html

Variant https://hexdocs.pm/bin_struct/BinStruct.Types.VariantOf.html

You can explore future via tests in test/ folder

## Configuration

  ```
    config :bin_struct,
      define_receive_send_tcp: true,
      define_receive_send_tls: true,
      enable_log_tcp: true,
      enable_log_tls: true
  ```

    tls implemented using :ssl application

    disable it or add ssl to list of extra_applications

  ```
    def application do
      [
        extra_applications: [:ssl]
      ]
    end
  ```


## Docs

https://hexdocs.pm/bin_struct

