defmodule BinStruct do

  @moduledoc """
  ## Overview

  ```
   iex> defmodule SimpleChildStruct do
   ...>  use BinStruct
   ...>  field :data, :uint8
   ...> end
   ...>
   ...> defmodule SimpleStructWithChild do
   ...>   use BinStruct
   ...>   field :child, SimpleChildStruct
   ...> end
   ...>
   ...> SimpleStructWithChild.new(child: SimpleChildStruct.new(data: 1))
   ...> |> SimpleStructWithChild.dump_binary()
   ...> |> SimpleStructWithChild.parse()
   ...> |> then(fn {:ok, struct, _rest } -> struct end)
   ...> |> SimpleStructWithChild.decode()
   %{ child: SimpleChildStruct.new(data: 1) }

  ```

  As you can see from example on above parsed structs and newly created are always equal thanks to intermediate type conversion called `unmanaged`.
  It's neither binary or managed and you are not suppose to work with it directly, by any type (including custom types) can perform
  automatic type conversion between `binary`, `managed` and `unmanaged` on developer request (using `registered_callback` api)

  BinStruct will automatically generate set if functions for you:

  1. `dump_binary/1`
  2. `size/1`
  3. `parse/2` will be present if is terminated (have rules defined to be parsed into finite struct from infinity bytestream)
  4. `parse_exact/2`
  5. `decode/2`
  6. `new/1`

  In additional with configuration it supports for now:

  ```elixir
  tls_receive()
  tls_send()
  tcp_receive()
  tcp_send()
  ```
  """

  alias BinStruct.Macro.Preprocess.Remap

  defmacro __using__(_opts) do

    Module.register_attribute(__CALLER__.module, :fields, accumulate: true)
    Module.register_attribute(__CALLER__.module, :options, accumulate: true)
    Module.register_attribute(__CALLER__.module, :callbacks, accumulate: true)
    Module.register_attribute(__CALLER__.module, :interface_implementations, accumulate: true)
    Module.register_attribute(__CALLER__.module, :compile_decode_single, accumulate: true)
    Module.register_attribute(__CALLER__.module, :compile_decode_only_no_label, accumulate: true)
    Module.register_attribute(__CALLER__.module, :compile_decode_only_with_labels, accumulate: true)

    quote do
      import BinStruct
      require Logger

      @before_compile BinStruct

    end

  end

  @doc """

  ## Overview

  Virtual field is powerful system which can help you in many ways working with complex data.

  Virtual field will act as Field at most cases, including automatic type conversion.

  It can be represented as any type available for Field and in special :unspecified form.

  Setting virtual field to :unspecified type will make automatic type conversions impossible but will give you opportunity
  to set it to any elixir term.

  ## How virtual fields behave in new context (when creating new struct)

  When creating new struct with virtual fields you suppose to provide value for virtual field or attach builder callback
  if you need intermediate value as cache.

  Any builder callbacks can read that value in any type conversion and create for you actual binary data.

  ## How virtual fields behave in parse context (when parsing)

  Virtual fields can be requested by any registered callback in any type conversion (in case it's :unspecified only 'managed') available.

  Only values for virtual fields requested will be produced and exactly once per field and type conversion pair.

  This behaviour can make them useful is a cache while parsing.

  Any virtual field in recursive dependency of requested virtual field will be produced as well and only once rule will still work.

  If A depends on B and B itself is requested in same type conversion A and B producing callbacks will be called once per such virtual field.

  More idea of how and why you can use it currently you can find in test/virtual_field_system

  I will try to provide more detailed info on this topic later.

  ## How virtual fields behave in decode context (when reading data)

  They will be present in decoded data.

  ## Supported Options

  ### read_by

    ```
    virtual :v_field_name, :uint8, read_by: &callback/1
    ```

    Source of this virtual field.

    This callback will be called once.

    On decode it's always called to produce output.

    On parse this callback will be called only if this virtual field is direct or indirect dependency of other callbacks.

  ### builder

  ```
  virtual :v_field_name, :binary_utf16, builder: &callback/1
  ```

  Callback which virtual field will be created from during creation of new struct.

  This value could be used from any other builders with any requested automatic type conversion.

  Virtual field will act as intermediate storage while you creating new struct. Useful separation effect and cache effect.

  ### optional

    ```
    virtual :v_field_name, :uint8, optional: true
    ```
    Makes field optional

  """

  defmacro virtual(name, type, opts \\ []) do

    raw_virtual_field = { :virtual_field, name, type, opts }

    Module.put_attribute(__CALLER__.module, :fields, raw_virtual_field)

  end

  @doc """

  ## Overview

    With fields you are building the shape of your binary data.

    field/3 expected you to pass name and type of your field. Supported types can be found in Se more detailed explanation in [`types` doc](pages/types/binary.md).
    In additional you can pass another BinStruct itself and BinStructCustomType as type.

  ## Supported Options

  ### length and its length_by dynamic version

    ```
    field :value, :binary, length: 1
    field :value, :binary, length_by: &callback/1
    ```

    length expect you to pass integer and field will be set strict to this length
    same for length_by but it receiving callback returning integer instead

  ### validate_by

    ```
    field :value, :uint8, validate_by: &callback/1
    ```

    Expecting callback returning true of data is valid and false if not
    In case field is invalid parse will stop and { :wrong_data, _wrong_data_binary } will be returned.
    Used by dynamic variant by dispatching.

  ### optional

    ```
    field :v_always, :uint8
    field :v_opt_tail1, :uint8, optional: true
    field :v_opt_tail2, :uint8, optional: true
    ```

    Optional, also known as optional tail is the way stop parsing struct when
    there is no more binary data and left all optional fields which not populated set to nil

  ### optional_by

    ```
    field :value, :uint8, optional_by: &callback/1
    ```

    Conditionally present or not value.

    Callback should return either true if value should be present or false otherwise.

  ### item_size and item_size_by (`list_of` only)

    ```
    field :value, { :list_of, Item }, item_size: 2
    field :value, { :list_of, Item }, item_size_by:  &callback/1
    ```

   Se more detailed explanation in [`list_of` doc](pages/types/list_of.md)

  ### count and count_by (`list_of` only)

   ```
    field :value, { :list_of, Item }, count: 2
    field :value, { :list_of, Item }, count_by: &callback/1
   ```

   Se more detailed explanation in [`list_of` doc](pages/types/list_of.md)

  ### take_while_by (`list_of` only)

    ```
    field :value, { :list_of, Item }, take_while_by: &callback/1
    ```

   Se more detailed explanation in [`list_of` doc](pages/types/list_of.md)

  ### builder

    ```
    field :value, :uint8, builder: &callback/1
    ```

   Builder callback will automatically build value for field.
   It should return 'managed' value, type conversion to underlying 'unmanaged' and 'binary' will be applied automatically.
   Builder callback called when you are creating struct via new/1 function.
   Builder can't request option argument, options are parse only tools.
   Field built with Builder can be requested from another builder, introducing chain. Calling order will be resolved automatically.

  """

  defmacro field(name, type, opts \\ []) do

    raw_field = { name, type, opts }

    Module.put_attribute(__CALLER__.module, :fields, raw_field)

  end

  @doc """

  ## Overview

    Called in module with use BinStruct defined will register option with given name.

    ```
    register_option :name_of_opt
    ```

    It can be created using option_(your_option_name)(value) generated function

    ```
    YourBinStruct.option_name_of_opt(value)
    ```

    Multiple options are chained with pipe operator

    ```
    YourBinStruct.option_name_of_opt(value)
    |> YourBinStruct.option_name_of_opt2(value)
    |> YourBinStruct.option_name_of_opt3(value)
    ```

    If requested from same module it's registered in use short notation name_of_opt: :option

    ```
    register_callback &callback/1, name_of_opt:  :option
    ```

    Full notation is

    ```
    register_callback &callback/1, name_of_opt: { type: :option, interface: YourBinStruct }
    ```

  """

  defmacro register_option(name, parameters \\ []) do

    raw_registered_option = { name, parameters }

    Module.put_attribute(__CALLER__.module, :options, raw_registered_option)
  end

  @doc """

  Called in module with use BinStruct defined will register callback.

  RegisteredCallback is main source of dynamic behaviour.

  It's binding arguments from current parse routine along with options from total parse tree context to function you pass in.
  Automatically manipulating with type conversion on request.

    ```

      iex> defmodule StructWithRegisteredCallbackRequestField do
      ...>   use BinStruct
      ...>
      ...>   register_callback &len_callback/1, len: :field
      ...>
      ...>   field :len, :uint32_be
      ...>   field :data, :binary, length_by: &len_callback/1
      ...>
      ...>   defp len_callback(len), do: len
      ...>
      ...> end

    ```

    ```

      iex> defmodule StructWithRegisteredCallbackRequestFieldInTypeConversion do
      ...>   use BinStruct
      ...>
      ...>   alias BinStruct.TypeConversion.TypeConversionBinary
      ...>
      ...>   register_callback &payload_builder/1, number: %{ type: :field, type_conversion: TypeConversionBinary }
      ...>
      ...>   field :number, :uint32_be
      ...>   field :payload, :binary, builder: &payload_builder/1
      ...>
      ...>   defp payload_builder(number_bin), do: number_bin
      ...>
      ...> end

    ```

    ```

      iex> defmodule StructWithRegisteredCallbackRequestOption do
      ...>   use BinStruct
      ...>
      ...>   register_option :opt
      ...>
      ...>   register_callback &data_length/1, opt: :option
      ...>
      ...>   field :data, :binary, length_by: &data_length/1
      ...>
      ...>   defp data_length(opt), do: opt
      ...>
      ...> end
      ...>
      ...> { :ok, struct, "" = _rest } = StructWithRegisteredCallbackRequestOption.parse(<<1>>, StructWithRegisteredCallbackRequestOption.option_opt(1))
      ...> StructWithRegisteredCallbackRequestOption.decode(struct)
      %{ data: <<1>> }

    ```

  """

  defmacro register_callback(function, args \\ []) do

    raw_registered_callback = { function, args }

    Module.put_attribute(__CALLER__.module, :callbacks, raw_registered_callback)
  end


  @doc """

  # BinStruct Options Interface

  ## Overview

  When a module with `use BinStruct` is defined, it will implement the options interface after the struct is fully parsed by default.

  The options interface allows for dynamic behavior based on field values, enabling more complex parsing logic and interdependencies between different parts of a binary structure.

  ## Basic Usage

  Options can be registered and implemented in a struct, and then used by other structs that reference it.

  ### With Separate Interface Module

  ```elixir
  defmodule SharedOptions do
    use BinStructOptionsInterface

      @type shared_option :: :a | :b

      register_option :shared_option
    end

    defmodule StructImplementingOptionsInterface do
      use BinStruct

      register_callback &impl_options_interface_1/1, data: :field

      impl_interface SharedOptions, &impl_options_interface_1/1

      field :data, :binary, length: 1

      defp impl_options_interface_1("A"), do: SharedOptions.option_shared_option(:a)
      defp impl_options_interface_1("B"), do: SharedOptions.option_shared_option(:b)
    end

    defmodule ParentOfStructImplementingOptionsInterface do
      use BinStruct

      register_callback &dependent_field_len/1, shared_option: %{ type: :option, interface: SharedOptions }

      field :child, StructImplementingOptionsInterface
      field :dependent_field, :binary, length_by: &dependent_field_len/1

      defp dependent_field_len(:a), do: 1
      defp dependent_field_len(:b), do: 2
    end

    { :ok, _struct, "" = _rest } = ParentOfStructImplementingOptionsInterface.parse("A1")
    { :ok, _struct, "" = _rest } = ParentOfStructImplementingOptionsInterface.parse("B22")
  ```

  ### Using Options Within the Same Struct

  With the `for: :field_name` option, you can use options within the same struct, creating internal dependencies between fields.

  ```elixir
  defmodule ChildUsingOption do
    use BinStruct

    register_callback &validate_f1_equal_option_a2/2,
                      f1: :field,
                      a: :option

    register_option :a

    field :f1, :uint8, validate_by: &validate_f1_equal_option_a2/2

    defp validate_f1_equal_option_a2(f1, a), do: f1 == a
  end

  defmodule ParentPassingOptions do
    use BinStruct

    register_callback &callback/1,
                    f: :field

    field :f, :uint8
    field :child, ChildUsingOption

    impl_interface ChildUsingOption, &callback/1, for: :child

    defp callback(f) do
      ChildUsingOption.option_a(f)
    end
  end

  # Example usage
  child = ChildUsingOption.new(f1: 1)
  parent = ParentPassingOptions.new(f: 1, child: child)
  parent_binary = ParentPassingOptions.dump_binary(parent)
  { :ok, parsed_parent, "" } = ParentPassingOptions.parse(parent_binary)
  ```

  ## Key Concepts

  1. **Options Registration**: Use `register_option :option_name` to define available options.

  2. **Callbacks Registration**: Use `register_callback` to define functions that will determine option values.
   - Specify dependencies with `field_name: :field` for field dependencies
   - Specify option dependencies with `option_name: :option`

  3. **Interface Implementation**: Use `impl_interface Module, &function/arity` to implement an options interface.
   - Add `for: :field_name` to specify the field for which the options are implemented.

  4. **Validation**: Options can be used for validation through callbacks that verify field values against option values.

  ## Common Patterns

  ### Parent-Child Option Passing

  This pattern allows a parent struct to pass options to its child structs, enabling the child's behavior to be determined by the parent's field values.

  ### Self-Validating Structs

  By using the `for: :field_name` syntax, a struct can implement an options interface for itself, enabling field values to be validated against options derived from other fields within the same struct.

  """

  defmacro impl_interface(interface, callback, options \\ []) do

    raw_interface_implementation = { interface, callback, options }

    Module.put_attribute(__CALLER__.module, :interface_implementations, raw_interface_implementation)

  end


  defmacro compile_decode_only(label \\ nil, decode_only_names) do

    case decode_only_names do
      decode_only_names when is_list(decode_only_names) ->

        all_atoms =
          Enum.all?(
            decode_only_names,
            fn decode_only_name ->
              is_atom(decode_only_name)
            end
          )

        if !all_atoms do
          raise "compile_decode_only accepts list of field_names as atoms as [ :a, :b ], got: #{inspect(decode_only_names)}"
        end

      _ ->
          raise "compile_decode_only accepts list of field_names as atoms as [ :a, :b ], got: #{inspect(decode_only_names)}"
    end

    case label do
      nil -> Module.put_attribute(__CALLER__.module, :compile_decode_only_no_label, decode_only_names)
      label -> Module.put_attribute(__CALLER__.module, :compile_decode_only_with_labels, { label, decode_only_names })
    end

  end

  defmacro compile_decode_single(label, field_name) do


    if !is_atom(label) do
      raise "compile_decode_single accepts function name as first argument :decode_single_value, got: #{inspect(label)}"
    end


    if !is_atom(field_name) do
      raise "compile_decode_single accepts :field_name atom as second argument, got: #{inspect(field_name)}"
    end

    Module.put_attribute(__CALLER__.module, :compile_decode_single, { label, field_name })

  end


  defp is_bin_struct_terminated_function(is_bin_struct_terminated) do

    quote do

      def is_bin_struct_terminated() do
        unquote(is_bin_struct_terminated)
      end

    end

  end

  defp known_total_size_bytes_function(known_total_size_bytes) do

    quote do

      def known_total_size_bytes() do
        unquote(known_total_size_bytes)
      end

    end

  end


  defmacro __before_compile__(env) do

    alias BinStruct.Macro.Structs.Field
    alias BinStruct.Macro.Structs.RegisteredOption
    alias BinStruct.Macro.NonVirtualFields
    alias BinStruct.Macro.Structs.RegisteredOptionsMap

    raw_fields = Module.get_attribute(env.module, :fields) |> Enum.reverse()
    raw_registered_options = Module.get_attribute(env.module, :options) |> Enum.reverse()
    raw_registered_callbacks = Module.get_attribute(env.module, :callbacks) |> Enum.reverse()
    raw_interface_implementations = Module.get_attribute(env.module, :interface_implementations) |> Enum.reverse()

    compile_decode_single = Module.get_attribute(env.module, :compile_decode_single) |> Enum.reverse()
    compile_decode_only_no_label = Module.get_attribute(env.module, :compile_decode_only_no_label) |> Enum.reverse()
    compile_decode_only_with_labels = Module.get_attribute(env.module, :compile_decode_only_with_labels) |> Enum.reverse()

    fields = Remap.remap_raw_fields(raw_fields, env)

    non_virtual_fields = NonVirtualFields.skip_virtual_fields(fields)

    registered_options = Remap.remap_raw_registered_options(raw_registered_options, env)
    registered_callbacks = Remap.remap_raw_registered_callbacks(raw_registered_callbacks, fields, registered_options, env)

    interface_implementations = Remap.remap_raw_interface_implementations(raw_interface_implementations, env)

    registered_callbacks_map = BinStruct.Macro.Structs.RegisteredCallbacksMap.new(registered_callbacks, env)

    virtual_fields = fields -- non_virtual_fields

    validate_read_by_not_using_option_arguments(virtual_fields, registered_callbacks_map)

    is_bin_struct_terminated =
      BinStruct.Macro.Termination.is_current_bin_struct_terminated(
        non_virtual_fields,
        env
      )

    dump_binary_function =
      BinStruct.Macro.DumpBinaryFunction.dump_binary_function(
        non_virtual_fields,
        env
      )

    parse_functions =
      BinStruct.Macro.ParseFunction.parse_function(
        non_virtual_fields,
        interface_implementations,
        registered_callbacks_map,
        env,
        _is_should_be_defined_private = !is_bin_struct_terminated
      )

    decode_function = BinStruct.Macro.Decode.DecodeFunction.decode_function(fields, registered_callbacks_map, env)

    decode_single_functions =
      Enum.map(
        compile_decode_single,
        fn { label, field_name } ->

          BinStruct.Macro.Decode.DecodeFunction.decode_single_function(
            fields,
            registered_callbacks_map,
            label,
            field_name,
            env
          )

        end
      )

    decode_only_labeled =
      Enum.map(
        compile_decode_only_with_labels,
        fn { label, decode_only_names } ->

          BinStruct.Macro.Decode.DecodeFunction.decode_only_labeled_function(
            fields,
            registered_callbacks_map,
            label,
            decode_only_names,
            env
          )

        end
      )

    decode_only_unlabeled =
      Enum.map(
        compile_decode_only_no_label,
        fn decode_only_names ->

          BinStruct.Macro.Decode.DecodeFunction.decode_only_unlabeled_function(
            fields,
            registered_callbacks_map,
            decode_only_names,
            env
          )

        end
      )

    decode_only_unlabeled_fallback =
      BinStruct.Macro.Decode.DecodeFunction.decode_only_unlabeled_fallback_to_decode_all_with_warning_function()


    new_function = BinStruct.Macro.NewFunction.new_function(fields, registered_callbacks_map, env)

    size_function =
      BinStruct.Macro.SizeFunction.size_function(
        non_virtual_fields,
        env
      )

    children_bin_structs =
      BinStruct.Macro.ChildrenBinStructs.children_bin_structs(
        non_virtual_fields,
        env
      )

    options_default_values_function =
      BinStruct.Macro.InUseOnlyDefaultOptionsFunction.default_options_function(registered_callbacks, children_bin_structs, env)

    option_functions =
      Enum.map(
       registered_options,
       fn %RegisteredOption{ name: name, parameters: parameters } ->
         BinStruct.Macro.OptionFunction.option_function(name, parameters, env)
       end
      )

    registered_options_map =
      RegisteredOptionsMap.new(
        registered_options,
        env
      )

    registered_options_map_access_function =

      quote do
        def __registered_options_map__() do

          unquote(
            Macro.escape(registered_options_map)
          )

        end

      end

    has_optional_fields =
      Enum.any?(
        non_virtual_fields,
        fn field -> BinStruct.Macro.IsOptionalField.is_optional_field(field)  end
      )

    known_total_size_bytes =

      if has_optional_fields do
        :unknown
      else
        BinStruct.Macro.AllFieldsSize.get_all_fields_size_bytes(
          non_virtual_fields
        )
      end

    struct_fields =
      Enum.map(
        non_virtual_fields,
        fn %Field{} = field ->

          %Field{ name: name } = field

          { name, nil }

        end
      ) |> Keyword.new()

    define_receive_send_tcp = Application.get_env(:bin_struct, :define_receive_send_tcp, false)
    define_receive_send_tls = Application.get_env(:bin_struct, :define_receive_send_tls, false)
    enable_log_tcp = Application.get_env(:bin_struct, :enable_log_tcp, true)
    enable_log_tls = Application.get_env(:bin_struct, :enable_log_tls, true)

    maybe_send = [

      (if define_receive_send_tcp do
        BinStruct.Macro.SendFunctions.tcp_send(enable_log_tcp)
      end),

      (if define_receive_send_tls do
         BinStruct.Macro.SendFunctions.tls_send(enable_log_tls)
       end)

    ] |> Enum.reject(&is_nil/1)


    maybe_receive =

      case { is_bin_struct_terminated, known_total_size_bytes } do

        { _is_bin_struct_terminated = false, _known_total_size_bytes } -> []

        { _is_bin_struct_terminated = true, known_total_size_bytes } when is_integer(known_total_size_bytes) ->

          [
            (if define_receive_send_tcp do
              BinStruct.Macro.ReceiveFunctions.tpc_receive_function_known_size(known_total_size_bytes, enable_log_tcp)
            end),

            (if define_receive_send_tls do
               BinStruct.Macro.ReceiveFunctions.tls_receive_function_known_size(known_total_size_bytes, enable_log_tls)
             end)
          ] |> Enum.reject(&is_nil/1)

        { _is_bin_struct_terminated = true, _known_total_size_bytes = :unknown } ->

          [
            (if define_receive_send_tcp do
               BinStruct.Macro.ReceiveFunctions.tpc_receive_function_unknown_size(enable_log_tcp)
             end),

            (if define_receive_send_tls do
               BinStruct.Macro.ReceiveFunctions.tls_receive_function_unknown_size(enable_log_tls)
             end)

          ] |> Enum.reject(&is_nil/1)

      end

     result_quote =
        quote do

          defstruct unquote(struct_fields)

          unquote(new_function)
          unquote(dump_binary_function)
          unquote(options_default_values_function)
          unquote_splicing(parse_functions)
          unquote_splicing(option_functions)

          unquote(decode_function)
          unquote_splicing(decode_single_functions)
          unquote_splicing(decode_only_labeled)
          unquote_splicing(decode_only_unlabeled)
          unquote(decode_only_unlabeled_fallback)


          unquote(size_function)

          unquote(
            known_total_size_bytes_function(known_total_size_bytes)
          )

          unquote(
            is_bin_struct_terminated_function(is_bin_struct_terminated)
          )

          unquote_splicing(
            BinStruct.Macro.Parse.CollapseOptionsIntoMap.define_functions()
          )

          unquote(
            registered_options_map_access_function
          )

          unquote_splicing(maybe_receive)
          unquote_splicing(maybe_send)


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

          def __module_type__(), do: :bin_struct

      end

     module_code = BinStruct.Macro.MacroDebug.code(result_quote)

     #if env.module == Exp.StructWithItems do
      #BinStruct.Macro.MacroDebug.puts_code(result_quote)
     #end

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

  defp validate_read_by_not_using_option_arguments(virtual_fields, registered_callbacks_map) do


    Enum.each(
      virtual_fields,
      fn virtual_field ->

        %BinStruct.Macro.Structs.VirtualField{opts: opts} = virtual_field

        case opts[:read_by] do
          read_by when not is_nil(read_by) ->

            registered_read_by_callback =
              BinStruct.Macro.Structs.RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, read_by)

            %BinStruct.Macro.Structs.RegisteredCallback{arguments: arguments} = registered_read_by_callback

            has_option_argument =
              Enum.any?(arguments, fn argument ->

                case argument do
                  %BinStruct.Macro.Structs.RegisteredCallbackOptionArgument{} -> true
                  _ -> false
                end

              end)

            if has_option_argument do
              raise "read_by callback used to construct virtual fields can't relay on option argument type, options is available only in parse context"
            end

          _ -> :ok

        end

      end
    )

  end

end
