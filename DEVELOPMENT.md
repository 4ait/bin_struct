## Development Notes

I expect developing cycle of this library to be in iterative manner.

It was not the same long ago then it was firstly developed for running one of our product.

Then it adapted for requirements of another products and so on.

So it's in first place is production grade library, not an abstract or experimental one.

Many can find redundancy in syntax and lack of shortcuts, this is expected.

General structure will help in future to implement and optimize more features required for more complex products.

Next most desired feature for me is typesafe layer.
I'm waiting for types to be implemented into elixir and code editors and i will implement it into this library.

---

## Development

There is such tools as

1. BinStruct.Macro.MacroDebug.puts_code/1
2. BinStruct.Macro.Parse.ParseTopologyDebug.print_topology/2

which may help in complex situations while developing, optimizing or generated code is not compiling.

In most cases module_code/0 function should be enough.

---

## Testing

```sh
mix test
```

---