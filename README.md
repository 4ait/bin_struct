# BinStruct

**BinStruct** is a library that provides a rich set of tools for parsing and encoding binaries.

The goal is to write declarations that are **readable now and will remain readable for years**. Your code will closely resemble a page from protocol documentation, ensuring clarity and maintainability.

This library is particularly beneficial for use cases that require **bidirectional data flow**.

## What BinStruct is not

BinStruct is not an protocol itself, there is no goal to replace asn1, protobuf, erlang binary term or any other protocols. if you can solve your problem using existing protocol - stick with it.

BinStruct is not replacement for binary pattern matching. If your job can be done via pattern match only it will be always better to use it directly.
There is layer of complexity this lib adds to make it achive it's main goal - write declarations, generate implementations automatically. When complexity grows only sane way to keep with it has general declarative structure of each part you working this.

BinStruct is by no means a framework and does not force you to follow any specific structure of how its parts will be used together. 
Each BinStruct you create is completely self-contained and can be used as you see fit. Whether you want to validate CRC, add encryption, or implement something else inside or outside—it’s entirely up to you, and the library imposes no restrictions on these choices.

## What BinStruct is primarily

BinStruct is s tool. Tool to support developer from very beggining with reach set of generated features, allowing to exlore data in every step, to very end running your app in production.

I believe BinStruct is an essential tool for developers. Simply transferring declarations from your protocol documentation into BinStruct special syntax is enough to start parsing your data, decoding it, and exploring its structure. This lets you build an understanding of how to proceed next.
It is especially helpful when working with a protocol that is new to you. If you’re unsure where to start or what to focus on, just transfer what you see in the documentation into BinStruct declarations and experiment. At some point, things will start falling into place, and you might even find that the application almost writes itself before you realize it.
Even the smallest fragments you implement can already be put to use. You can parse and decode binary data to gain a better understanding of what you're dealing with without needing to fully implement every detail or dynamic callback. You'll gradually build out your protocol implementation step by step, and over time, these pieces will naturally connect as your codebase grows.
You don’t need all the advanced features like virtual fields, auto-generated fields (builders), or type conversions beyond the basic managed (human-readable) one right away. You can always add them later if you think they’ll make the process easier.

## Performance 

The library compiles into Elixir binary pattern match and uses optimizations like composing every part with known size into single pattern, 
always inlining for encoders and static values, caching every requested value.

If in registered_callback field `B` requested for value from `A` and `C` requested for value from  `A`, `A` will be converted to requested type conversion before `B` (late as possible) and later passed same value to `C`.
All functions, except for main public function like `parse/2`, are declared in the same module and marked as private (`defp`), giving maximum optimization opportunities for the Erlang compiler (`erlc`). 

You can expect performance equal to manually written pattern matches, with some differences: modular structure,
validation after each step, and creating structs as the result. It is not correct to compare simple manual parsing patterns directly to what this library does. 

If, in some case, the library performs worse than regular pattern matching, please open an issue.

## Installation

To get started, add `BinStruct` to your `mix.exs` dependencies:

```elixir
def deps do
  [
    {:bin_struct, "~> 0.2"}
  ]
end
```

---

## Syntax overview

  ```elixir
  
  defmodule PngChunk do
  
    use BinStruct
  
    #all dynamic behaviour is callback
    #if we are not specifying type_conversion this is always 'managed' also known as 'human readable'
    register_callback &data_length/1, length: :field
  
    #with fields you build shape of your binary data
    field :length, :uint32_be
  
    #use expanded constructs whenever possible, this is both easier to read and will be validated at parse time
    #its always better to expand arrays/flags/enums even if you don't use them for now, it will help moving forward
    #as you will have more complete picture
    #and also it will give you opportunity to be dispatched as dynamic variant later (read it as if we received something and it has type distinct from listed below it's not this struct, we can catch it via upper variant_of later)
    field :type, {
      :enum,
      %{
        type: :binary,
        values: [
          "IHDR",
          "PLTE",
          "IDAT",
          "IEND",
          "cHRM",
          "gAMA",
          "iCCP",
          "sBIT",
          "sRGB",
          "bKGD",
          "hIST",
          "tRNS",
          "pHYs",
          "sPLT",
          "tIME",
          "tEXt",
          "zTXt",
          "iTXt"
        ]
      }
    }, length: 4
  
    #consuming dynamic behaviour into length_by
    field :data, :binary, length_by: &data_length/1
  
    field :crc, :uint32_be
  
    #dynamic behaviour implementation
    #we returning always 'managed' type conversion, in this case length field will be automatically converted to elixir number
    #and we return this number as it
    defp data_length(length), do: length
  
  end
  
  ```

## Getting Started

### Explore Examples

Start by exploring the examples folder. Run the following commands to see an example in action:

```sh
mix run examples/png.exs
mix run examples/extraction_from_integer.exs
mix run examples/extraction_from_buffer.exs
mix run examples/packet_via_higher_order_macro.exs
mix run examples/recursive_sequence.exs
```

### Reference Documentation

- [BinStruct Module Documentation](https://hexdocs.pm/bin_struct/BinStruct.html)

#### Type-Specific Docs

- [StaticValue](https://hexdocs.pm/bin_struct/static_value.html)
- [Binary](https://hexdocs.pm/bin_struct/binary.html)
- [Enum](https://hexdocs.pm/bin_struct/enum.html)
- [Flags](https://hexdocs.pm/bin_struct/flags.html)
- [List](https://hexdocs.pm/bin_struct/list_of.html)
- [Variant](https://hexdocs.pm/bin_struct/variant_of.html)

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

---
