defmodule SharedInterface do

  use BinStructOptionsInterface

  register_options_interface do
    register_option :length_indicator
    register_option :presence_indicator
  end

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

