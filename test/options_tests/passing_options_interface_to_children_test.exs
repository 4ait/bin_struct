defmodule BinStructTest.OptionsTests.PassingOptionsInterfaceToChildrenTest do

  use ExUnit.Case

  defmodule SharedInterface do

    use BinStructOptionsInterface

    @type length_indicator :: integer()
    @type presence_indicator :: :content_not_present | :content_present

    register_options_interface do
      register_option :length_indicator
      register_option :presence_indicator
    end

  end

  defmodule Child do

    use BinStruct

    register_callback &optional_by/1,
                      presence_indicator: %{ type: :option, interface: SharedInterface }

    register_callback &length_by/1,
                      length_indicator: %{ type: :option, interface: SharedInterface }

    field :content, :binary,
          optional_by: &optional_by/1,
          length_by: &length_by/1

    defp length_by(length_indicator), do: length_indicator

    defp optional_by(:content_present), do: true
    defp optional_by(:content_not_present), do: false

  end

  defmodule TransportHeader do

    use BinStruct

    register_callback &impl_options_interface/2,
                      presence_indicator: :field,
                      length_indicator: :field

    impl_interface SharedInterface, &impl_options_interface/2

    field :presence_indicator, {
      :enum,
      %{
        type: :uint8,
        values: [
          { 0x00, :content_not_present },
          { 0x01, :content_present },
        ]
      }
    }

    field :length_indicator, :uint16_be

    defp impl_options_interface(presence_indicator, length_indicator) do
      SharedInterface.option_presence_indicator(presence_indicator)
      |> SharedInterface.option_length_indicator(length_indicator)
    end

  end

  defmodule Parent do

    use BinStruct

    field :header, TransportHeader
    field :child, Child

  end


  test "could parse struct by externally passed options from interface" do

    child = Child.new(content: nil)

    parent =
      Parent.new(
        header:
          TransportHeader.new(
            presence_indicator: :content_not_present,
            length_indicator: 0
          ),
        child: child
      )

    dump = Parent.dump_binary(parent)

    { :ok, parsed_struct, "" = _rest } = Parent.parse(dump)

    values = Parent.decode(parsed_struct)

    %{
      child: ^child
    } = values

  end


end

