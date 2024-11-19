defmodule BinStructTest.OptionsTests.ImplementingMultipleOptionInterfacesTest do

  use ExUnit.Case

  defmodule Interface1 do

    use BinStructOptionsInterface

    register_option :o1

  end

  defmodule Interface2 do

    use BinStructOptionsInterface

    register_option :o2

  end

  defmodule Interface3 do

    use BinStructOptionsInterface

    register_option :o3

  end

  defmodule OptionsReceiver do

    use BinStruct

    register_callback &length_by/3,
              o1: %{ type: :option, interface: Interface1 },
              o2: %{ type: :option, interface: Interface2 },
              o3: %{ type: :option, interface: Interface3 }

    field :data, :binary, length_by: &length_by/3

    defp length_by(o1, o2, o3) do
      o1 + o2 + o3
    end


  end

  defmodule OptionsSender do


    use BinStruct

    register_callback &impl_options_interface_1/1, a1: :field
    register_callback &impl_options_interface_2/1, a2: :field
    register_callback &impl_options_interface_3/1, a3: :field

    field :a1, :uint16_be
    field :a2, :uint16_be
    field :a3, :uint16_be

    impl_interface Interface1, &impl_options_interface_1/1
    impl_interface Interface2, &impl_options_interface_2/1
    impl_interface Interface3, &impl_options_interface_3/1

    defp impl_options_interface_1(a1), do: Interface1.option_o1(a1)
    defp impl_options_interface_2(a2), do: Interface2.option_o2(a2)
    defp impl_options_interface_3(a3), do: Interface3.option_o3(a3)

  end

  defmodule TransportHeader do

    use BinStruct

    field :options_sender, OptionsSender
    field :options_receiver, OptionsReceiver

  end


  test "could parse struct by externally passed options from interface" do

    options_sender = OptionsSender.new(a1: 1, a2: 2, a3: 3)
    options_receiver = OptionsReceiver.new(data: "123456")

    header =
      TransportHeader.new(
        options_sender: options_sender,
        options_receiver: options_receiver
      )

    dump = TransportHeader.dump_binary(header)

    { :ok, parsed_struct, "" = _rest, options } = TransportHeader.parse_returning_options(dump)

    %{
      Interface1 => %{ o1: 1 },
      Interface2 => %{ o2: 2 },
      Interface3 => %{ o3: 3 }
    } = options

    values = TransportHeader.decode(parsed_struct)

    %{
      options_sender: ^options_sender,
      options_receiver: ^options_receiver
    } = values

  end


end

