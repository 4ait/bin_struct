defmodule BinStruct.Macro.Termination do

  alias BinStruct.Macro.Structs.Field

  def is_current_bin_struct_terminated(_no_fields = [], _env), do: true

  def is_current_bin_struct_terminated(fields, env) do

    case is_terminated_by_optional_sequence(fields, env) do
      true -> is_fields_terminated(fields, env)
      false -> false
    end

  end

  def is_module_terminated(module_info) do

    case module_info do

      %{
        module_type: :bin_struct,
        module_full_name: module_full_name
      } ->
        is_bin_struct_terminated(module_full_name)

      %{
        module_type: :bin_struct_custom_type,
        module_full_name: module_full_name,
      } ->

        is_bin_struct_custom_type_terminated(module_full_name)

    end

  end

  defp is_bin_struct_terminated(module_full_name) do
    apply(module_full_name, :is_bin_struct_terminated, [])
  end

  def is_bin_struct_custom_type_terminated(module_full_name) do
    Kernel.function_exported?(module_full_name, :parse_returning_options, 3)
  end


  defp is_fields_terminated([ last_field | []], _env), do: is_field_terminated(last_field)

  defp is_fields_terminated([ head_field | tail_field], env) do

    if is_field_terminated(head_field) do
      is_fields_terminated(tail_field, env)
    else
      raise "Only last field of bin_struct without termination allowed."
    end

  end

  defp is_terminated_by_optional_sequence(fields, _env) do

    is_optional_sequence =
      Enum.map(
        fields,
        fn field ->

          %Field{ opts: opts } = field

          if opts[:optional] do
            true
          else
            false
          end

        end
      )

    deduplicated_sequences = Enum.dedup(is_optional_sequence)

    case Enum.count(deduplicated_sequences) do

      1 ->

        is_first_element_optional = Enum.at(deduplicated_sequences, 0)

        if is_first_element_optional do
          _is_terminated = false
        else
          _is_terminated = true
        end

      2 ->

        is_first_element_optional = Enum.at(deduplicated_sequences, 0)

        if is_first_element_optional do
          raise "optional elements only allowed as continuous sequence on struct tail"
        else
          _is_terminated = false
        end

      _more -> raise "incontinuous optional sequence not allowed"

    end

  end

  defp is_field_terminated(%Field{} = field) do

    %Field{ type: type, opts: opts } = field

    is_type_terminated(type, opts)

  end

  defp is_type_terminated(type, opts) do

    length_by = opts[:length_by]

    case BinStruct.Macro.FieldSize.type_size_bits(type, opts) do

      size_bits when is_integer(size_bits) -> true

      :unknown ->

        case type do

          {:list_of, list_of_info } ->

            case list_of_info do
              %{ type: :static } -> true
              %{ type: :runtime_bounded } -> true
              %{ type: :variable, termination: :terminated } -> true
              %{ type: :variable, termination: :not_terminated } -> false
            end

          _type when not is_nil(length_by) -> true

          { :module, child_module_info } -> is_module_terminated(child_module_info)

          {:variant_of, variants } ->

            Enum.all?(
              Enum.map(
                variants,
                fn { :module, child_module_info } -> is_module_terminated(child_module_info)
                end
              )
            )

          :binary -> false

        end

    end

  end



end