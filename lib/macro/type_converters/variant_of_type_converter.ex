defmodule BinStruct.Macro.TypeConverters.VariantOfTypeConverter do

  alias BinStruct.Macro.TypeConverterToBinary
  alias BinStruct.Macro.Bind

  def from_managed_to_unmanaged_variant_of({ :variant_of, _variants }, quoted) do
    quoted
  end


  def from_unmanaged_to_managed_variant_of({ :variant_of, _variants }, quoted) do
    quoted
  end

  def from_unmanaged_to_binary_variant_of({ :variant_of, variants }, quoted) do

    patterns =
      Enum.map(
        variants,
        fn variant ->

          { :module, module_info }  = variant

          %{
            module_type: :bin_struct,
            module_full_name: module_full_name
          } = module_info


          bin_struct_access_bind = { String.to_atom("bin_struct"), [], __MODULE__ }

          left =
            quote do
              %unquote(module_full_name){} = unquote(bin_struct_access_bind)
            end

          right = TypeConverterToBinary.convert_unmanaged_value_to_binary({ :module, module_info }, bin_struct_access_bind)

          BinStruct.Macro.Common.case_pattern(left, right)

        end
      )

    quote do

      case unquote(quoted) do
        unquote(patterns)
      end

    end

  end

end