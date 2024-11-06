defmodule Interface1 do

  use BinStructOptionsInterface

  register_options_interface do
    register_option :o1
  end

end

defmodule Interface2 do

  use BinStructOptionsInterface

  register_options_interface do
    register_option :o2
  end

end

defmodule Interface3 do

  use BinStructOptionsInterface

  register_options_interface do
    register_option :o3
  end

end

defmodule TestStruct do


  use BinStruct

  register_callback &impl_options_interface_1/1, a: :field
  register_callback &impl_options_interface_2/1, b: :field
  register_callback &impl_options_interface_3/1, c: :field

  field :a, :uint16_be
  field :b, :uint16_be
  field :c, :binary

  impl_interface Interface1, &impl_options_interface_1/1
  impl_interface Interface2, &impl_options_interface_2/1
  impl_interface Interface3, &impl_options_interface_3/1

  defp impl_options_interface_1(a), do: Interface1.option_o1(a)
  defp impl_options_interface_2(b), do: Interface2.option_o2(b)
  defp impl_options_interface_3(c), do: Interface3.option_o3(c)

end