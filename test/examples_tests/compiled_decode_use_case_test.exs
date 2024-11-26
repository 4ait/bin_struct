defmodule BinStructTest.ExamplesTests.CompiledDecodeUseCaseTest do

  use ExUnit.Case, async: true

  test "example test compiled_decode_use_case.exs" do

    example_file = "examples/compiled_decode_use_case.exs"

    { output, exit_code } = System.cmd("mix", ["run", example_file], env: [{"MIX_ENV", "test"}], stderr_to_stdout: true)

    # Assert that the script executed successfully
    assert exit_code == 0, "Script failed with exit code #{exit_code}. Output: #{output}"

  end

end
