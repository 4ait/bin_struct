defmodule BinStruct.Docs.Asn1 do

  @moduledoc """


  Asn1 is BinStructCustomType and using erlang asn1 compiler output as implementation.

  Asn1 modules and types can be compiled using this command

   ```
      erlc -o "$OUTPUT_DIR" -I "$OUTPUT_DIR" +noobj -bper +maps +undec_rest TEST-ASN1.asn1
   ```

  +maps is optional, change -bper to your target encoding (erlang compiler support BER, PER and so on)
  +undec_rest is required to current BinStructCustomType implementation,
  but this may be non-ideal and sometimes shadow errors in data, returning :not_enough_bytes instead


   ```
      defmodule Struct do
        use BinStruct

        alias BinStruct.BuiltIn.Asn1

        field :asn1, { Asn1, asn1_module: :"TEST-ASN1", asn1_type: :"SimpleType" }
      end
    ```
  """

end
