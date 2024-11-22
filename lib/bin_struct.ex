defmodule BinStruct do

  @moduledoc """

  ## BinStruct

  BinStruct is main builder block for this library.

  ## Configuration

    tls implemented using :ssl application

    disable it or add ssl to list of extra_applications

    ```

      def application do
        [
          extra_applications: [:ssl]
        ]
      end

    ```

    ```

      config :bin_struct,
        define_receive_send_tcp: true,
        define_receive_send_tls: true,
        enable_log_tcp: true,
        enable_log_tls: true

    ```

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

    As you can see from example on above parsed structs and newly created are always equal thanks to intermediate type conversion called 'unmanaged'.
    It's neither binary or managed and you are not suppose to work with it directly, by any type (including custom types) can perform
    automatic type conversion between 'binary', 'managed' and 'unmanaged' on developer request (using registered_callback api)

    BinStruct will automatically generate set if functions for you:

        1. dump_binary/1
        2. size/1
        3. parse/2 will be present if is terminated (have rules defined to be parsed into finite struct from infinity bytestream)
        4. parse_exact/2
        4. decode/2
        4. new/1

    In additional with configuration it supports for now:

        tls_receive()
        tls_send()
        tcp_receive()
        tcp_send()


  ## How to implement your protocol wrapping struct using higher order macro

    Best way to implement wrapper is by creating  higher order macro which will create BinStruct for you

  ```

      iex> defmodule PacketProtocolHeader do
      ...>   use BinStruct
      ...>   field :version, <<0>>
      ...>   field :length, :uint32_be
      ...> end
      ...>
      ...> defmodule Packet do
      ...>
      ...>  defmacro __using__(_opts) do
      ...>
      ...>    quote do
      ...>      import Packet
      ...>    end
      ...>
      ...>  end
      ...>
      ...>   defmacro content(content_field_name, content_field_type) do
      ...>     quote do
      ...>       use BinStruct
      ...>
      ...>       # Register callbacks for dynamic fields
      ...>       register_callback &header_builder/1,
      ...>                        [{unquote(content_field_name), :field}]
      ...>       register_callback &content_length/1, header: :field
      ...>
      ...>       # Define the header field
      ...>       field :header, PacketProtocolHeader, builder: &header_builder/1
      ...>
      ...>       # Define the content field with length_by
      ...>       field unquote(content_field_name), unquote(content_field_type),
      ...>             length_by: &content_length/1
      ...>
      ...>       # Callback to build the header dynamically
      ...>       defp header_builder(content) do
      ...>         PacketProtocolHeader.new(%{
      ...>           length: unquote(content_field_type).size(content)
      ...>         })
      ...>       end
      ...>
      ...>       # Callback to calculate content length from the header
      ...>       defp content_length(header) do
      ...>         %{length: length} = PacketProtocolHeader.decode(header)
      ...>         length
      ...>       end
      ...>     end
      ...>   end
      ...> end
      ...>
      ...> defmodule StructInsidePacket do
      ...>   use BinStruct
      ...>   field :data, :binary
      ...> end
      ...>
      ...> defmodule StructInsidePacket.Packet do
      ...>   use Packet
      ...>   content :content, StructInsidePacket
      ...> end
      ...>
      ...> packet = StructInsidePacket.Packet.new(
      ...>   content: StructInsidePacket.new(data: "123")
      ...> )
      ...>
      ...> binary = StructInsidePacket.Packet.dump_binary(packet)
      ...> {:ok, packet, _rest} = StructInsidePacket.Packet.parse(binary)
      ...> %{ content: content } = StructInsidePacket.Packet.decode(packet)
      ...> StructInsidePacket.decode(content)
      %{ data: "123" }

    ```

    it will set length for content automatically for now, and if your packet has required info to be used inside parsing tree
    you can always later implement some BinStructOptionsInterface for header and this context will be available
    as simple as ..register_callback.., some_option_from_header: { type: :option, interface: PacketProtocolHeader } from any struct in tree

  """

  alias BinStruct.Macro.Preprocess.Remap

  defmacro __using__(_opts) do

    Module.register_attribute(__CALLER__.module, :fields, accumulate: true)
    Module.register_attribute(__CALLER__.module, :options, accumulate: true)
    Module.register_attribute(__CALLER__.module, :callbacks, accumulate: true)
    Module.register_attribute(__CALLER__.module, :interface_implementations, accumulate: true)

    quote do
      import BinStruct
      require Logger

      @before_compile BinStruct

    end

  end

  @doc """

  ## Examples

  """

  defmacro virtual(name, type, opts \\ []) do

    raw_virtual_field = { :virtual_field, name, type, opts }

    Module.put_attribute(__CALLER__.module, :fields, raw_virtual_field)

  end

  @doc """

  With fields you are building the shape of your binary data.

  field/3 expected you to pass name and type of your field. Supported types can be found in bin_struct/types.
  In additional you can pass another BinStruct itself and BinStructCustomType as type.

  ## Supported Options

  ### length and its length_by dynamic version

    field :value, :binary, length: 1
    field :value, :binary, length_by: &callback/1

    length expect you to pass integer and field will strict to this length
    same for length_by by it receiving callback returning integer instead


  ### validate_by

    field :value, :uint8, validate_by: &callback/1

    Expecting callback returning true of data is valid and false if not
    In case field is invalid parse will stop and { :wrong_data, _wrong_data_binary } will be returned.
    Used by dynamic variant by dispatching.

  ### optional

    field :value, :uint8, optional: true
    field :value, :uint8, optional: false

    Optional, also known as optional tail is the way stop parsing struct of there
    is no more binary data and left all optional fields which not populated set to nil


  ### optional_by

    field :value, :uint8, optional_by: &callback/1

    Conditionally present or not value.

    Callback should return either true if value should be present or false otherwise.


  ### item_size and item_size_by (ListOf only)

    field :value, :uint8, optional_by: &callback/1

  ### count and count_by (ListOf only)

    field :value, :uint8, optional_by: &callback/1

  ### take_while_by (ListOf only)

  field :value, :uint8, optional_by: &callback/1

  """

  defmacro field(name, type, opts \\ []) do

    raw_field = { name, type, opts }

    Module.put_attribute(__CALLER__.module, :fields, raw_field)

  end

  @doc """

      Called in module with use BinStruct defined will register option with given name.

      It can be created using option_(your_option_name)(value) generated function

      Options can be requested with registered_callback using name_of_opt: { type: :option, interface: YourBinStruct }
      or if requested from same module it's defined with short notation name_of_opt: :option

  """

  defmacro register_option(name, parameters \\ []) do

    raw_registered_option = { name, parameters }

    Module.put_attribute(__CALLER__.module, :options, raw_registered_option)
  end

  @doc """

      Called in module with use BinStruct defined will register callback.

      RegisteredCallback is main source of dynamic behaviour.

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

  Called in module with use BinStruct defined will implement options interface after struct fully parsed.

  ```

      iex> defmodule SharedOptions do
      ...>   use BinStructOptionsInterface
      ...>
      ...>   @type shared_option :: :a | :b
      ...>
      ...>   register_option :shared_option
      ...>
      ...> end
      ...>
      ...>
      ...>  defmodule StructImplementingOptionsInterface do
      ...>   use BinStruct
      ...>
      ...>   register_callback &impl_options_interface_1/1, data: :field
      ...>
      ...>   impl_interface BinStructOptionsInterface, &impl_options_interface_1/1
      ...>
      ...>   field :data, :binary, length: 1
      ...>
      ...>   defp impl_options_interface_1("A"), do: SharedOptions.option_shared_option(:a)
      ...>   defp impl_options_interface_1("B"), do: SharedOptions.option_shared_option(:b)
      ...>
      ...> end
      ...>
      ...> defmodule ParentOfStructImplementingOptionsInterface do
      ...>   use BinStruct
      ...>
      ...>   register_callback &dependent_field_len/1, shared_option: %{ type: :option, interface: SharedOptions }
      ...>
      ...>   field :child, StructImplementingOptionsInterface
      ...>   field :dependent_field, :binary, length_by: &dependent_field_len/1
      ...>
      ...>   defp dependent_field_len(:a), do: 1
      ...>   defp dependent_field_len(:b), do: 2
      ...>
      ...> end
      ...>
      ...> { :ok, _struct, "" = _rest } = ParentOfStructImplementingOptionsInterface.parse("A1")
      ...> { :ok, _struct, "" = _rest } = ParentOfStructImplementingOptionsInterface.parse("B22")

    ```

  """

  defmacro impl_interface(interface, callback) do

    raw_interface_implementation = { interface, callback }

    Module.put_attribute(__CALLER__.module, :interface_implementations, raw_interface_implementation)

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

    raw_fields = Module.get_attribute(env.module, :fields) |> Enum.reverse()
    raw_registered_options = Module.get_attribute(env.module, :options) |> Enum.reverse()
    raw_registered_callbacks = Module.get_attribute(env.module, :callbacks) |> Enum.reverse()
    raw_interface_implementations = Module.get_attribute(env.module, :interface_implementations) |> Enum.reverse()

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

    decode_function = BinStruct.Macro.DecodeFunction.decode_function(fields, registered_callbacks_map, env)

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

    known_total_size_bytes =
      BinStruct.Macro.AllFieldsSize.get_all_fields_size_bytes(
        non_virtual_fields
      )

    struct_fields =
      Enum.map(
        non_virtual_fields,
        fn %Field{} = field ->

          %Field{ name: name } = field

          { name, nil }

        end
      ) |> Keyword.new()

    define_receive_send_tcp = Application.get_env(:bin_struct, :define_receive_send_tcp, true)
    define_receive_send_tls = Application.get_env(:bin_struct, :define_receive_send_tls, true)
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

     decode_field_function = BinStruct.Macro.DecodeFieldFunction.decode_field_function_implemented_via_decode_all(env)

     result_quote =
        quote do

          defstruct unquote(struct_fields)

          unquote(decode_field_function)
          unquote(new_function)
          unquote(dump_binary_function)
          unquote(options_default_values_function)
          unquote_splicing(parse_functions)
          unquote_splicing(option_functions)

          unquote(decode_function)
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