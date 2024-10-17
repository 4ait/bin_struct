defmodule BinStruct do

  alias BinStruct.Macro.Preprocess.Remap

  defmacro __using__(_opts) do

    Module.register_attribute(__CALLER__.module, :fields, accumulate: true)
    Module.register_attribute(__CALLER__.module, :options, accumulate: true)
    Module.register_attribute(__CALLER__.module, :callbacks, accumulate: true)
    Module.register_attribute(__CALLER__.module, :interface_implementations, accumulate: true)

    quote do
      import BinStruct
      require Logger

      unquote(
        BinStruct.Encoder.encoders()
      )

      @before_compile BinStruct

    end

  end

  defmacro virtual(name, type, opts \\ []) do

    raw_virtual_field = { :virtual_field, name, type, opts }

    Module.put_attribute(__CALLER__.module, :fields, raw_virtual_field)

  end

  defmacro field(name, type, opts \\ []) do

    raw_field = { name, type, opts }

    Module.put_attribute(__CALLER__.module, :fields, raw_field)

  end

  defmacro one_of([do: block]) do

    { :__block__, _meta, fields } = block

    raw_fields =
      Enum.map(
        fields,
        fn field ->

          { :field, _meta, [ name, type, opts ] } = field

          _raw_field = { name, type, opts }

        end
      )

    one_of_pack = { :one_of_pack, raw_fields }

    Module.put_attribute(__CALLER__.module, :fields, one_of_pack)

  end

  defmacro register_option(name, parameters \\ []) do

    raw_registered_option = { name, parameters }

    Module.put_attribute(__CALLER__.module, :options, raw_registered_option)
  end

  defmacro register_callback(function, args \\ []) do

    raw_registered_callback = { function, args }

    Module.put_attribute(__CALLER__.module, :callbacks, raw_registered_callback)
  end


  defmacro define_is_bin_struct_terminated(is_bin_struct_terminated) do

    quote do

      def is_bin_struct_terminated() do
        unquote(is_bin_struct_terminated)
      end

    end

  end

  defmacro define_known_total_size_bytes(known_total_size_bytes) do

    quote do

      def known_total_size_bytes() do
        unquote(known_total_size_bytes)
      end

    end

  end


  defmacro impl_interface(interface, callback) do

    raw_interface_implementation = { interface, callback }

    Module.put_attribute(__CALLER__.module, :interface_implementations, raw_interface_implementation)

  end

  defmacro __before_compile__(env) do

    alias BinStruct.Macro.Structs.Field
    alias BinStruct.Macro.Structs.RegisteredOption
    alias BinStruct.Macro.NonVirtualFields

    raw_fields = Module.get_attribute(env.module, :fields) |> Enum.reverse()
    raw_registered_options = Module.get_attribute(env.module, :options) |> Enum.reverse()
    raw_registered_callbacks = Module.get_attribute(env.module, :callbacks) |> Enum.reverse()
    raw_interface_implementations = Module.get_attribute(env.module, :interface_implementations) |> Enum.reverse()

    fields_and_one_of_packs = Remap.remap_raw_fields_and_one_of_packs(raw_fields, env)

    fields = BinStruct.Macro.ExpandOneOfPacksFields.expand_one_of_packs_fields(fields_and_one_of_packs)

    non_virtual_fields_and_one_of_packs = NonVirtualFields.skip_virtual_fields(fields_and_one_of_packs)
    non_virtual_fields = NonVirtualFields.skip_virtual_fields(fields)

    registered_options = Remap.remap_raw_registered_options(raw_registered_options, env)
    registered_callbacks = Remap.remap_raw_registered_callbacks(raw_registered_callbacks, fields, registered_options, env)

    interface_implementations = Remap.remap_raw_interface_implementations(raw_interface_implementations, env)

    registered_callbacks_map = BinStruct.Macro.Structs.RegisteredCallbacksMap.new(registered_callbacks, env)

    is_bin_struct_terminated =
      BinStruct.Macro.Termination.is_current_bin_struct_terminated(
        non_virtual_fields_and_one_of_packs,
        env
      )

    dump_binary_function =
      BinStruct.Macro.DumpBinaryFunction.dump_binary_function(
        non_virtual_fields,
        env
      )

    dump_io_data_function =
      BinStruct.Macro.DumpIoDataFunction.dump_io_data(
        non_virtual_fields,
        env
      )

    parse_functions =
      BinStruct.Macro.ParseFunction.parse_function(
        non_virtual_fields_and_one_of_packs,
        interface_implementations,
        registered_callbacks_map,
        env,
        _is_should_be_defined_private = !is_bin_struct_terminated
      )

    decode_function = BinStruct.Macro.DecodeFunction.decode_function(fields, registered_callbacks_map, env)
    decode_field_functions = BinStruct.Macro.DecodeFieldFunction.decode_field_functions(fields, registered_callbacks_map, env)

    decode_field_functions =
      case decode_field_functions do
        [] -> []

        decode_field_functions ->

          declare_head =
            quote do
              def decode_field(struct, field_name, opts \\ [])
            end

          [ declare_head | decode_field_functions]

      end

    new_function = BinStruct.Macro.NewFunction.new_function(fields, registered_callbacks_map)

    size_function =
      BinStruct.Macro.SizeFunction.size_function(
        non_virtual_fields_and_one_of_packs,
        env
      )

    children_bin_structs =
      BinStruct.Macro.ChildrenBinStructs.children_bin_structs(
        non_virtual_fields,
        env
      )

    options_default_values_function =
      BinStruct.Macro.DefaultOptionsFunction.default_options_function(registered_callbacks, children_bin_structs, env)

    option_functions =
      Enum.map(
       registered_options,
       fn %RegisteredOption{ name: name, parameters: parameters } ->
         BinStruct.Macro.OptionFunction.option_function(name, parameters, env)
       end
      )

    known_total_size_bytes =
      BinStruct.Macro.AllFieldsSize.get_all_fields_and_packs_size_bytes(
        non_virtual_fields_and_one_of_packs
      )

    struct_fields =
      Enum.map(
        non_virtual_fields,
        fn %Field{} = field ->

          %Field{ name: name } = field

          { name, nil }

        end
      ) |> Keyword.new()

    maybe_receive =
      case { is_bin_struct_terminated, known_total_size_bytes } do

        { _is_bin_struct_terminated = false, _known_total_size_bytes } -> []

        { _is_bin_struct_terminated = true, known_total_size_bytes } when is_integer(known_total_size_bytes) ->
          [
            BinStruct.Macro.ReceiveFunctions.tpc_receive_function_known_size(known_total_size_bytes),
            BinStruct.Macro.ReceiveFunctions.tls_receive_function_known_size(known_total_size_bytes)
          ]

        { _is_bin_struct_terminated = true, _known_total_size_bytes = :unknown } ->
          [
            BinStruct.Macro.ReceiveFunctions.tpc_receive_function_unknown_size(),
            BinStruct.Macro.ReceiveFunctions.tls_receive_function_unknown_size()
          ]

      end

     result_quote =
        quote do

          defstruct unquote(struct_fields)

          unquote(new_function)
          unquote(dump_binary_function)
          unquote(dump_io_data_function)
          unquote(options_default_values_function)
          unquote_splicing(parse_functions)
          unquote_splicing(decode_field_functions)
          unquote_splicing(option_functions)

          unquote(decode_function)
          unquote(size_function)

          define_known_total_size_bytes(unquote(known_total_size_bytes))
          define_is_bin_struct_terminated(unquote(is_bin_struct_terminated))

          unquote_splicing(
            BinStruct.Macro.Parse.CollapseOptionsIntoMap.define_functions()
          )

          unquote_splicing(maybe_receive)

          unquote_splicing([
            BinStruct.Macro.SendFunctions.tcp_send(),
            BinStruct.Macro.SendFunctions.tls_send()
          ])

          def parse_exact_returning_options(bin, options \\ nil) do

            case parse_returning_options(bin, options) do
              { :ok, parsed, "", options } -> { :ok, parsed, options }
              { :ok, _parsed, non_empty_binary, _options } -> raise "non empty binary left after parse exact call #{inspect(non_empty_binary)}"
              { :wrong_data, _wrong_data } = wrong_data_clause -> wrong_data_clause
              :not_enough_bytes -> raise "not_enough_bytes returned from parse exact"
            end

          end

          def parse_exact(bin, options \\ nil) do

            case parse(bin, options) do
              { :ok, parsed, "" } -> { :ok, parsed }
              { :ok, _parsed, non_empty_binary } -> raise "non empty binary left after parse exact call #{inspect(non_empty_binary)}"
              { :wrong_data, _wrong_data } = wrong_data_clause -> wrong_data_clause
              :not_enough_bytes -> raise "not_enough_bytes returned from parse exact"
            end

          end

          def parse_decode_exact(bin, options \\ nil) do

            case parse_decode(bin, options) do
              { :ok, parsed, "" } -> { :ok, parsed }
              { :ok, _parsed, non_empty_binary } -> raise "non empty binary left after parse exact call #{inspect(non_empty_binary)}"
              { :wrong_data, _wrong_data } = wrong_data_clause -> wrong_data_clause
              :not_enough_bytes -> raise "not_enough_bytes returned from parse exact"
            end

          end

      end

     module_code = BinStruct.MacroDebug.code(result_quote)

      quote do

        unquote(result_quote)

        unquote(

          if Mix.env() != :prod do

            quote do

              def module_code() do
                code = unquote(module_code)
                IO.puts(code)
              end

            end

          end
        )

      end

  end

end