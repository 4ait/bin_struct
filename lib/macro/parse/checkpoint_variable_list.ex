defmodule BinStruct.Macro.Parse.CheckpointVariableList do

  alias BinStruct.Macro.Parse.ListOfBoundaryConstraintFunctionCall
  alias BinStruct.Macro.Structs.RegisteredCallbacksMap
  alias BinStruct.Macro.Structs.Field
  alias BinStruct.Macro.Parse.Validation
  alias BinStruct.Macro.Parse.WrapWithOptionalBy
  alias BinStruct.Macro.Bind
  alias BinStruct.Macro.IsPrimitiveType
  alias BinStruct.Macro.RegisteredCallbackFunctionCall
  alias BinStruct.Macro.Parse.DeconstructOptionsForField


  def variable_terminated_until_length_by_parse_checkpoint(
         %{
           item_type: item_type,
           any_length: any_length
         } = _list_of_info,
         %Field{} = field,
         function_name,
         value_arguments_binds,
         interface_implementations,
         registered_callbacks_map,
         _env
       ) do


    %Field{ name: name, opts: opts } = field

    optional_by = opts[:optional_by]

    field_name_access = { Bind.bind_value_name(name), [], __MODULE__ }
    parse_until_length_by_parse_function_name = String.to_atom("#{function_name}_until_length_by_parse")

    recursive_parse_functions =
      case item_type do
        { :module,  %{ module: module } } ->

          #call for length, check is binary of such length is available then parse as a whole

          empty_binary_clause =
            quote do

              def unquote(parse_until_length_by_parse_function_name)(<<>>, _options, acc) do
                :lists.reverse(acc)
              end

            end

          main_clause =

            quote do

              def unquote(parse_until_length_by_parse_function_name)(binary, options, acc) when is_binary(binary) and is_list(acc) do

                { :ok, struct, rest } = unquote(module).parse(binary, options)

                new_acc = [ struct | acc ]

                unquote(parse_until_length_by_parse_function_name)(rest, options, new_acc)

              end

            end

          [empty_binary_clause, main_clause]

      end

    body =
      quote do

        length =
          unquote(
            ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(
              any_length,
              registered_callbacks_map,
              __MODULE__
            )
          )

        if length >= byte_size(unquote(field_name_access)) do

          <<unquote(field_name_access)::size(length)-bytes, rest::binary>> = unquote(field_name_access)

          structs = unquote(parse_until_length_by_parse_function_name)(unquote(field_name_access), options, [])

          { :ok, structs, rest, options }

        else
          :not_enough_bytes
        end

      end

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, __MODULE__)

    validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, body, __MODULE__)

    checkpoint_function =
      quote do

        defp unquote(function_name)(
               unquote(field_name_access) = _bin,
               unquote_splicing(value_arguments_binds),
               options
             ) when is_binary(unquote(field_name_access)) do

          unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

          unquote(
            WrapWithOptionalBy.maybe_wrap_with_optional_by(validate_and_return_clause, optional_by, field_name_access, registered_callbacks_map, __MODULE__)
          )

        end

      end

    [ checkpoint_function ] ++ recursive_parse_functions

  end

  def variable_terminated_until_count_by_parse_checkpoint(
         %{
           item_type: item_type,
           any_count: any_count
         }  = _list_of_info,
         %Field{} = field,
         function_name,
         value_arguments_binds,
         interface_implementations,
         registered_callbacks_map,
         _env
       ) do

    %Field{ name: name, opts: opts } = field

    optional_by = opts[:optional_by]
    field_name_access = { Bind.bind_value_name(name), [], __MODULE__ }

    parse_until_count_by_parse_function_name = String.to_atom("#{function_name}_until_count_by_parse")

    recursive_parse_functions =
      case item_type do
        { :module,  %{ module: module } } ->

          #call for length, check is binary of such length is available then parse as a whole

          empty_binary_clause =
            quote do

              def unquote(parse_until_count_by_parse_function_name)(binary, _options, _remain = 0, acc) do
                { :lists.reverse(acc), binary }
              end

            end

          main_clause =

            quote do

              def unquote(parse_until_count_by_parse_function_name)(binary, options, remain, acc) when is_binary(binary) and is_list(acc) do

                { :ok, struct, rest } = unquote(module).parse(binary, options)

                new_acc = [ struct | acc ]

                unquote(parse_until_count_by_parse_function_name)(rest, options, remain - 1, new_acc)

              end

            end

          [empty_binary_clause, main_clause]

      end


    body =
      quote do

        count =
          unquote(
            ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(
              any_count,
              registered_callbacks_map,
              __MODULE__
            )
          )

        { structs, rest } = unquote(parse_until_count_by_parse_function_name)(unquote(field_name_access), options, count, [])

        { :ok, structs, rest, options }

      end

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, __MODULE__)

    validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, body, __MODULE__)

    checkpoint_function =
      quote do

        defp unquote(function_name)(
               unquote(field_name_access) = _bin,
               unquote_splicing(value_arguments_binds),
               options
             ) when is_binary(unquote(field_name_access)) do

          unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

          unquote(
            WrapWithOptionalBy.maybe_wrap_with_optional_by(validate_and_return_clause, optional_by, field_name_access, registered_callbacks_map, __MODULE__)
          )

        end

      end

    [ checkpoint_function ] ++ recursive_parse_functions

  end

  def variable_terminated_take_while_by_callback_by_item_size_checkpoint(
        %{
          item_type: item_type,
          any_item_size: any_item_size,
          take_while_by: take_while_by
        }  = _list_of_info,
        %Field{} = field,
        function_name,
        value_arguments_binds,
        interface_implementations,
        registered_callbacks_map,
        _env
      ) do

    %Field{ name: name, opts: opts } = field

    optional_by = opts[:optional_by]

    value_bind_name = Bind.bind_value_name(name)

    field_name_access = { value_bind_name, [], __MODULE__ }
    item_bind_name = { :item, [], __MODULE__ }

    parse_take_while_by_callback_by_item_size_function_name = String.to_atom("#{function_name}_take_while_by_callback_by_item_size")

    is_item_of_primitive_type = IsPrimitiveType.is_primitive_type(item_type)

    parse_expr =
      case item_type do

        _item_type when is_item_of_primitive_type -> item_bind_name

        {:module, %{ module: module } = _module_info} ->

          quote do
            { :ok, struct } = unquote(module).parse_exact(unquote(item_bind_name), options)
            struct
          end

      end

    take_while_by_registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, take_while_by)

    take_while_by_function_call =
      RegisteredCallbackFunctionCall.registered_callback_function_call(
        take_while_by_registered_callback,
        __MODULE__
      )

    halt_clause =
      quote do

        def unquote(parse_take_while_by_callback_by_item_size_function_name)(binary, _options, _item_size, :halt = _flag, acc) do
          { :ok, :lists.reverse(acc), binary }
        end

      end

    not_enough_bytes_clause =
      quote do

        def unquote(parse_take_while_by_callback_by_item_size_function_name)(binary, _options, item_size, _flag, _acc) when is_integer(item_size) and byte_size(binary) < item_size do
          :not_enough_bytes
        end

      end

    main_clause =

      quote do

        def unquote(parse_take_while_by_callback_by_item_size_function_name)(binary, options, item_size, :cont = _flag, acc) when is_binary(binary) and is_list(acc) do

          <<unquote(item_bind_name)::size(item_size)-bytes, rest::binary>> = binary

          unquote(item_bind_name) = unquote(parse_expr)

          new_acc = [ unquote(item_bind_name) | acc ]
          unquote(field_name_access) = new_acc

          take_while_by_callback_result = unquote(take_while_by_function_call)

          case take_while_by_callback_result do
            :cont -> unquote(parse_take_while_by_callback_by_item_size_function_name)(rest, options, item_size, :cont, new_acc)
            :halt -> unquote(parse_take_while_by_callback_by_item_size_function_name)(rest, options, item_size, :halt, new_acc)
          end

        end

      end

    recursive_parse_functions = [ halt_clause, not_enough_bytes_clause, main_clause ]


    body =
      quote do

        item_size =
          unquote(
            ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(
              any_item_size,
              registered_callbacks_map,
              __MODULE__
            )
          )

         parse_function_call_result = unquote(parse_take_while_by_callback_by_item_size_function_name)(unquote(field_name_access), options, item_size, :cont, [])

          case parse_function_call_result do
            { :ok, items, rest } -> { :ok, items, rest, options }
            :not_enough_bytes -> :not_enough_bytes
          end

      end

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, __MODULE__)

    validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, body, __MODULE__)

    checkpoint_function =
      quote do

        defp unquote(function_name)(
               unquote(field_name_access) = _bin,
               unquote_splicing(value_arguments_binds),
               options
             ) when is_binary(unquote(field_name_access)) do

          unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

          unquote(
            WrapWithOptionalBy.maybe_wrap_with_optional_by(validate_and_return_clause, optional_by, field_name_access, registered_callbacks_map, __MODULE__)
          )

        end

      end

    [ checkpoint_function ] ++ recursive_parse_functions

  end


  def variable_terminated_take_while_by_callback_by_parse_checkpoint(
        %{
          item_type: item_type,
          take_while_by: take_while_by
        }  = _list_of_info,
        %Field{} = field,
        function_name,
        value_arguments_binds,
        interface_implementations,
        registered_callbacks_map,
        _env
      ) do

    %Field{ name: name, opts: opts } = field

    optional_by = opts[:optional_by]

    value_bind_name = Bind.bind_value_name(name)

    field_name_access = { value_bind_name, [], __MODULE__ }

    parse_take_while_by_callback_by_parse_function_name = String.to_atom("#{function_name}_take_while_by_callback_by_parse")

    take_while_by_registered_callback = RegisteredCallbacksMap.get_registered_callback_by_callback(registered_callbacks_map, take_while_by)

    take_while_by_function_call =
      RegisteredCallbackFunctionCall.registered_callback_function_call(
        take_while_by_registered_callback,
        __MODULE__
      )

    halt_clause =
      quote do

        def unquote(parse_take_while_by_callback_by_parse_function_name)(binary, _options, :halt = _flag, acc) do
          { :ok, :lists.reverse(acc), binary }
        end

      end

    { :module, %{ module_full_name: module_full_name } } = item_type

    main_clause =

      quote do

        def unquote(parse_take_while_by_callback_by_parse_function_name)(binary, options, :cont = _flag, acc) when is_binary(binary) and is_list(acc) do


          case unquote(module_full_name).parse(binary, options) do

            {:ok, new_item, rest } ->

              new_acc = [ new_item | acc ]

              unquote(field_name_access) = new_acc

              take_while_by_callback_result = unquote(take_while_by_function_call)

              case take_while_by_callback_result do
                :cont -> unquote(parse_take_while_by_callback_by_parse_function_name)(rest, options, :cont, new_acc)
                :halt -> unquote(parse_take_while_by_callback_by_parse_function_name)(rest, options, :halt, new_acc)
              end

            :not_enough_bytes -> :not_enough_bytes

            {:wrong_data, _wrong_data} = wrong_data -> wrong_data

          end



        end

      end

    recursive_parse_functions = [ halt_clause, main_clause ]


    body =
      quote do

        parse_function_call_result = unquote(parse_take_while_by_callback_by_parse_function_name)(unquote(field_name_access), options, :cont, [])

        case parse_function_call_result do
          { :ok, items, rest } -> { :ok, items, rest, options }
        end

      end

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, __MODULE__)

    validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, body, __MODULE__)

    checkpoint_function =
      quote do

        defp unquote(function_name)(
               unquote(field_name_access) = _bin,
               unquote_splicing(value_arguments_binds),
               options
             ) when is_binary(unquote(field_name_access)) do

          unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

          unquote(
            WrapWithOptionalBy.maybe_wrap_with_optional_by(validate_and_return_clause, optional_by, field_name_access, registered_callbacks_map, __MODULE__)
          )

        end

      end

    [ checkpoint_function ] ++ recursive_parse_functions

  end


  def variable_not_terminated_until_end_by_item_size_checkpoint(
        %{
          item_type: item_type,
          any_item_size: any_item_size
        } = _list_of_info,
        %Field{} = field,
        function_name,
        value_arguments_binds,
        interface_implementations,
        registered_callbacks_map,
        _env
      ) do


    %Field{ name: name, opts: opts } = field

    optional_by = opts[:optional_by]

    field_name_access = { Bind.bind_value_name(name), [], __MODULE__ }
    item_bind_name = { :item, [], __MODULE__ }

    is_item_of_primitive_type = IsPrimitiveType.is_primitive_type(item_type)

    parse_expr =

      case item_type do

        _item_type when is_item_of_primitive_type -> item_bind_name

        {:module, %{ module: module } = _module_info} ->

          quote do
            { :ok, struct } = unquote(module).parse_exact(unquote(item_bind_name), options)

            struct

          end

      end

    body =
      quote do

        item_size =
          unquote(
            ListOfBoundaryConstraintFunctionCall.function_call_or_unwrap_value(
              any_item_size,
              registered_callbacks_map,
              __MODULE__
            )
          )

        items =
          for << unquote(item_bind_name)::binary-size(item_size) <- unquote(field_name_access) >> do
            unquote(parse_expr)
          end

        { :ok, items, "", options }

      end

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, __MODULE__)

    validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, body, __MODULE__)

    checkpoint_function =
      quote do

        defp unquote(function_name)(
               unquote(field_name_access) = _bin,
               unquote_splicing(value_arguments_binds),
               options
             ) when is_binary(unquote(field_name_access)) do

          unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

          unquote(
            WrapWithOptionalBy.maybe_wrap_with_optional_by(validate_and_return_clause, optional_by, field_name_access, registered_callbacks_map, __MODULE__)
          )

        end

      end

    checkpoint_function

  end


  def variable_not_terminated_until_end_by_parse_checkpoint(
        %{
          item_type: item_type,
        } = _list_of_info,
        %Field{} = field,
        function_name,
        value_arguments_binds,
        interface_implementations,
        registered_callbacks_map,
        _env
      ) do


    %Field{ name: name, opts: opts } = field

    optional_by = opts[:optional_by]

    field_name_access = { Bind.bind_value_name(name), [], __MODULE__ }
    parse_until_end_by_parse_function_name = String.to_atom("#{function_name}_until_end_by_parse")

    recursive_parse_functions =
      case item_type do
        { :module,  %{ module: module } } ->

          #call for length, check is binary of such length is available then parse as a whole

          empty_binary_clause =
            quote do

              def unquote(parse_until_end_by_parse_function_name)(<<>>, _options, acc) do
                :lists.reverse(acc)
              end

            end

          main_clause =

            quote do

              def unquote(parse_until_end_by_parse_function_name)(binary, options, acc) when is_binary(binary) and is_list(acc) do

                { :ok, struct, rest } = unquote(module).parse(binary, options)

                new_acc = [ struct | acc ]

                unquote(parse_until_end_by_parse_function_name)(rest, options, new_acc)

              end

            end

          [empty_binary_clause, main_clause]

      end

    body =
      quote do

          structs = unquote(parse_until_end_by_parse_function_name)(unquote(field_name_access), options, [])

          { :ok, structs, "", options }

      end

    validate_patterns_and_prelude = Validation.validate_fields_with_patterns_and_prelude([field], registered_callbacks_map, __MODULE__)

    validate_and_return_clause = Validation.validate_and_return(validate_patterns_and_prelude, body, __MODULE__)

    checkpoint_function =
      quote do

        defp unquote(function_name)(
               unquote(field_name_access) = _bin,
               unquote_splicing(value_arguments_binds),
               options
             ) when is_binary(unquote(field_name_access)) do

          unquote(DeconstructOptionsForField.deconstruct_options_for_field(field, interface_implementations, registered_callbacks_map, __MODULE__))

          unquote(
            WrapWithOptionalBy.maybe_wrap_with_optional_by(validate_and_return_clause, optional_by, field_name_access, registered_callbacks_map, __MODULE__)
          )

        end

      end

    [ checkpoint_function ] ++ recursive_parse_functions

  end

end