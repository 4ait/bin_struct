defmodule BinStruct.Macro.Bind do

  @moduledoc false

  def bind_binary_value(name, context), do: { String.to_atom("b_val_#{name}"), [], context }
  def bind_unmanaged_value(name, context), do: { String.to_atom("um_val_#{name}"), [], context }
  def bind_managed_value(name, context), do: { String.to_atom("m_val_#{name}"), [], context }
  def bind_option(interface, option_name, context), do: { String.to_atom("opt_of_#{escape_module_name(interface)}_#{option_name}"), [], context }

  defp escape_module_name(atom_or_string) do

    string = "#{atom_or_string}"

    String.trim_leading(string, "Elixir.")
    |> String.replace(".", "")
    |> Macro.underscore()
  end

end