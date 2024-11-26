defmodule BinStructTest.ExamplesTests.RecursiveSequenceTest do

  use ExUnit.Case, async: true

  test "example test recursive_sequence.exs" do

    example_file = "examples/recursive_sequence.exs"

    { output, exit_code } = System.cmd("mix", ["run", example_file], env: [{"MIX_ENV", "test"}], stderr_to_stdout: true)

    # Assert that the script executed successfully
    assert exit_code == 0, "Script failed with exit code #{exit_code}. Output: #{output}"

  end

end
