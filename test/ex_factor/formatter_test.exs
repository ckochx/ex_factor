defmodule ExFactor.FormatterTest do
  use ExUnit.Case
  alias ExFactor.Formatter

  setup_all do
    File.mkdir_p("test/tmp")

    on_exit(fn ->
      File.rm_rf("test/tmp")
    end)
  end

  describe "format/1" do
    test "it should format the specified files" do
      content = """
      defmodule ExFactorSampleModule do
      # unindented line
          # overindented line
      end
      """

      File.write("test/tmp/test_module.ex", content)
      Formatter.format(["test/tmp/test_module.ex"])
      {:ok, formatted_file} = File.read("test/tmp/test_module.ex")
      assert formatted_file =~ "\n  # unindented line"
      assert formatted_file =~ "\n  # overindented line"
    end
  end
end
