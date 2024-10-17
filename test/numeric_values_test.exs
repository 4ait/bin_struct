defmodule BinStructTest.NumericValuesTest do

  use ExUnit.Case

  defmodule NumericBinStruct do

    use BinStruct

    field :uint8, :uint8
    field :int8, :int8

    field :uint16_be, :uint16_be
    field :uint32_be, :uint32_be
    field :uint64_be, :uint64_be
    field :int16_be, :int16_be
    field :int32_be, :int32_be
    field :int64_be, :int64_be
    field :float32_be, :float32_be
    field :float64_be, :float64_be

    field :uint16_le, :uint16_le
    field :uint32_le, :uint32_le
    field :uint64_le, :uint64_le
    field :int16_le, :int16_le
    field :int32_le, :int32_le
    field :int64_le, :int64_le
    field :float32_le, :float32_le
    field :float64_le, :float64_le

  end


  test "struct with numeric values works" do

    uint8_value = trunc(:math.pow(2, 8)) - 1
    uint16_value = trunc(:math.pow(2, 16)) - 1
    uint32_value = trunc(:math.pow(2, 32)) - 1
    uint64_value = trunc(:math.pow(2, 64)) - 1

    int8_value = trunc(:math.pow(2, 7)) - 1
    int16_value = trunc(:math.pow(2, 15)) - 1
    int32_value = trunc(:math.pow(2, 31)) - 1
    int64_value = trunc(:math.pow(2, 63)) - 1

    float32 = 0.5
    float64 = 1.5

    struct =
      NumericBinStruct.new(
       %{
         uint8: uint8_value,
         int8: int8_value,

         uint16_be: uint16_value,
         uint32_be: uint32_value,
         uint64_be: uint64_value,
         int16_be: int16_value,
         int32_be: int32_value,
         int64_be: int64_value,
         float32_be: float32,
         float64_be: float64,

         uint16_le: uint16_value,
         uint32_le: uint32_value,
         uint64_le: uint64_value,
         int16_le: int16_value,
         int32_le: int32_value,
         int64_le: int64_value,
         float32_le: float32,
         float64_le: float64

       }
      )

    values = NumericBinStruct.decode(struct)

    %{
      uint8: ^uint8_value,
      int8: ^int8_value,

      uint16_be: ^uint16_value,
      uint32_be: ^uint32_value,
      uint64_be: ^uint64_value,
      int16_be: ^int16_value,
      int32_be: ^int32_value,
      int64_be: ^int64_value,
      float32_be: ^float32,
      float64_be: ^float64,

      uint16_le: ^uint16_value,
      uint32_le: ^uint32_value,
      uint64_le: ^uint64_value,
      int16_le: ^int16_value,
      int32_le: ^int32_value,
      int64_le: ^int64_value,
      float32_le: ^float32,
      float64_le: ^float64
    } = values

  end

  test "negative numeric values works" do

    int8_value = (trunc(:math.pow(2, 7)) - 1) * -1
    int16_value = (trunc(:math.pow(2, 15)) - 1) * -1
    int32_value = (trunc(:math.pow(2, 31)) - 1) * -1
    int64_value = (trunc(:math.pow(2, 63)) - 1) * -1

    struct =
      NumericBinStruct.new(

        %{

          uint8: 0,
          uint16_be: 0,
          uint32_be: 0,
          uint64_be: 0,
          float32_be: 0.0,
          float64_be: 0.0,

          uint16_le: 0,
          uint32_le: 0,
          uint64_le: 0,
          float32_le: 0.0,
          float64_le: 0.0,

          int8: int8_value,

          int16_be: int16_value,
          int32_be: int32_value,
          int64_be: int64_value,

          int16_le: int16_value,
          int32_le: int32_value,
          int64_le: int64_value

        }

      )

    values = NumericBinStruct.decode(struct)

    %{
      int8: ^int8_value,

      int16_be: ^int16_value,
      int32_be: ^int32_value,
      int64_be: ^int64_value,

      int16_le: ^int16_value,
      int32_le: ^int32_value,
      int64_le: ^int64_value

    } = values

  end



end

