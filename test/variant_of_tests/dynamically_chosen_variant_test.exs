defmodule BinStructTest.VariantOfTests.DynamicallyChosenVariantTest do

  use ExUnit.Case

  defmodule Cookie do

    use BinStruct

    alias BinStruct.BuiltInCustomTypes.TerminatedBinary

    register_callback &check_if_starting_with_cookie_pattern/1,
                      binary: :field

    field :binary, { TerminatedBinary, termination: <<0>> },
          validate_by: &check_if_starting_with_cookie_pattern/1

    defp check_if_starting_with_cookie_pattern(binary) do
      String.starts_with?(binary, "Cookie: ")
    end


  end

  defmodule Token do

    use BinStruct

    alias BinStruct.BuiltInCustomTypes.TerminatedBinary

    register_callback &check_if_starting_with_token_pattern/1,
                      binary: :field


    field :binary, { TerminatedBinary, termination: <<0>> },
          validate_by: &check_if_starting_with_token_pattern/1

    defp check_if_starting_with_token_pattern(binary) do
      String.starts_with?(binary, "Token: ")
    end


  end

  defmodule TokenOrCookie do

    use BinStruct

    field :token_or_cookie, { :variant_of, [ Token, Cookie ]}


  end



  test "variant_of dynamically chosen correct child by validate_by" do

    token = Token.new(binary: "Token: SomeToken")
    cookie = Cookie.new(binary: "Cookie: SomeCookie")

    token_or_cookie_struct_initialized_with_token =
      TokenOrCookie.new(token_or_cookie: token)

    token_or_cookie_struct_initialized_with_cookie =
      TokenOrCookie.new(token_or_cookie: cookie)

    dump_variant_with_token = TokenOrCookie.dump_binary(token_or_cookie_struct_initialized_with_token)
    dump_variant_with_cookie = TokenOrCookie.dump_binary(token_or_cookie_struct_initialized_with_cookie)

    { :ok, parsed_struct_with_token_variant, _rest } = TokenOrCookie.parse(dump_variant_with_token)
    { :ok, parsed_struct_with_cookie_variant, _rest } = TokenOrCookie.parse(dump_variant_with_cookie)

    values_of_token_variant = TokenOrCookie.decode(parsed_struct_with_token_variant)
    values_of_cookie_variant = TokenOrCookie.decode(parsed_struct_with_cookie_variant)

    %{
      token_or_cookie: ^token
    } = values_of_token_variant

    %{
      token_or_cookie: ^cookie
    } = values_of_cookie_variant

  end

end

