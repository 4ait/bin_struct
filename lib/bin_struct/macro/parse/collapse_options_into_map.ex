defmodule BinStruct.Macro.Parse.CollapseOptionsIntoMap do

  @moduledoc false

  def define_functions() do

    [
      collapse_options_into_map_nil_clause(),
      collapse_options_into_map_empty_clause(),
      collapse_options_into_map_improper_head_clause(),
      collapse_options_into_map_main_clause()
    ]

  end

  defp collapse_options_into_map_nil_clause() do

    quote do

      defp collapse_options_into_map(%{} = options_into, nil = _options_from) do
        options_into
      end

    end

  end

  defp collapse_options_into_map_empty_clause() do

    quote do

      defp collapse_options_into_map(%{} = options_map, []) do
        options_map
      end

    end

  end

  defp collapse_options_into_map_improper_head_clause() do

    quote do

      defp collapse_options_into_map(%{} = options_map, [ head | tail ]) when is_list(head) do

        options_map = collapse_options_into_map(options_map, head)

        collapse_options_into_map(options_map, tail)

      end

    end

  end

  defp collapse_options_into_map_main_clause() do

    quote do


      defp collapse_options_into_map(%{} = options_map, [ head | tail ]) do

        { interface, name, value } = head

        options_map =
          case options_map do

            #someone using our interface option current hierarchy
            %{
              ^interface => %{
                ^name => _opt_name_in_use
              } = options_in_interface
            } = options_map  ->

              %{
                options_map |
                interface => %{
                  options_in_interface |
                  name => value
                }
              }

            #option of interface unused
            %{} = options_map -> options_map

          end

        collapse_options_into_map(options_map, tail)

      end

    end

  end


end