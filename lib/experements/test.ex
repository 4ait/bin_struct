defmodule StructWithOptionalFields do

  use BinStruct

  register_callback &always_present/0

  register_callback &present_if_optional_1_present/1,
                    optional_1: :field

  field :optional_1, :uint8, optional_by: &always_present/0
  field :optional_2, :uint8, optional_by: &present_if_optional_1_present/1

  def always_present(), do: true

  def present_if_optional_1_present(optional_1) when not is_nil(optional_1), do: true
  def present_if_optional_1_present(_optional_1), do: false

end