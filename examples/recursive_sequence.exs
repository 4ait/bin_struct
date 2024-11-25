
#defining entries our sequence can hold

#integer value
defmodule SeqInteger do

  use BinStruct

  field :tag, <<1>>
  field :length, { :static, BinStruct.PrimitiveEncoder.uint32_be(4) }
  field :value, :uint32_be

end

#string value
defmodule SeqString do

  use BinStruct

  register_callback &value_length/1, length: :field
  register_callback &length_builder/1, value: :field

  field :tag, <<2>>
  field :length, :uint32_be, builder: &length_builder/1
  field :value, :binary, length_by: &value_length/1

  defp value_length(length), do: length
  defp length_builder(value), do: byte_size(value)

end

#recurcive sequence itself
defmodule SeqSequence do

  use BinStruct

  alias BinStruct.BuiltIn.Recursive

  #X don't use recursive types directly, at compile time library is building picture of what is inside tree
  #it's calling every module to get it's properties, like does it have known length? does it can be parsed itself from infinity byte source?
  #field :sequence, Sequence

  #V with wrapping it with recursing custom type we delegating this work to get compile time picture to custom type itself
  #this way we can tell about this type to library manually via custom type args, customization is not implement yet tho
  field :sequence, { Recursive, module: Sequence }

end

#name - value pair for our sequence

defmodule NameValuePair do

  use BinStruct

  register_callback &name_field_length/1, name_length: :field
  register_callback &name_length_builder/1, name: :field

  field :name_length, :uint32_be, builder: &name_length_builder/1
  field :name, :binary, length_by: &name_field_length/1
  field :value, { :variant_of, [ SeqInteger, SeqString, SeqSequence ] }

  defp name_field_length(name_length), do: name_length
  defp name_length_builder(name), do: byte_size(name)

end


#sequence itself

defmodule Sequence do

  use BinStruct

  register_callback &length_of_sequence/1, length: :field
  register_callback &length_builder/1, items: :field

  field :tag, <<3>>
  field :length, :uint32_be, builder: &length_builder/1
  field :items, { :list_of, NameValuePair }, length_by: &length_of_sequence/1

  defp length_of_sequence(length), do: length

  defp length_builder(items) do

    Enum.reduce(
      items,
      0,
      fn item, acc -> acc + NameValuePair.size(item) end
    )

  end

end

integer_value_pair = NameValuePair.new(name: "integer_key", value: SeqInteger.new(value: 1))
string_value_pair =  NameValuePair.new(name: "string_key", value: SeqString.new(value: "string val"))

nested_sequence = Sequence.new(items: [ NameValuePair.new(name: "integer_key_in_nested_sequence", value: SeqInteger.new(value: 2)) ])

sequence_value_pair = NameValuePair.new(name: "nested_sequence", value: SeqSequence.new(sequence: nested_sequence) )

created_sequence =
  Sequence.new(items: [
    integer_value_pair,
    string_value_pair,
    sequence_value_pair
  ])

IO.inspect(created_sequence, label: "Created")

sequence_in_binary_form = Sequence.dump_binary(created_sequence)

{ :ok, sequence, "" = _rest } = Sequence.parse(sequence_in_binary_form)

IO.inspect(sequence, label: "Received")
