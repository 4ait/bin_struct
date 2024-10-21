defmodule BinStruct.Macro.Bind do

  def bind_value_name(name), do: String.to_atom("val_#{name}")

  def bind_managed_value_name(name), do: String.to_atom("m_val_#{name}")

  def bind_option_name(interface, option_name), do: String.to_atom("opt_of_#{escape_module_name(interface)}_#{option_name}")

  defp escape_module_name(atom_or_string) do

    string = "#{atom_or_string}"

    String.trim_leading(string, "Elixir.")
    |> String.replace(".", "")
    |> Macro.underscore()
  end

end