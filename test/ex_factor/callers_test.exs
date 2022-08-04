defmodule ExFactor.CallersTest do
  use ExUnit.Case
  alias ExFactor.Callers

  describe "callers/1" do
    test "it should report callers of a module" do
      callers = Callers.callers(ExFactor.Parser)

      assert Enum.find(callers, fn caller -> caller.file == "lib/ex_factor/callers.ex" end)
      %{} = support = Enum.find(callers, fn caller -> caller.file == "test/support/support.ex" end)
      assert support.caller_module == ExFactor.Support
      assert support.callee == {ExFactor.Parser, :all_functions, 1}
    end

    test "when no callers" do
      assert [] = Callers.callers(ExFactor.NotAModule)
    end
  end

  describe "callers/3" do
    test "it should report callers of a module" do
      [one, _two, _three] =
        ExFactor.Parser
        |> Callers.callers(:all_functions, 1)
        |> Enum.sort_by(& &1.file)

      assert one.caller_module == ExFactor.Callers
      assert one.file == "lib/ex_factor/callers.ex"
      assert one.line == 9
    end

    test "it converts strings to atoms" do
      [one, _two, _three] =
        "ExFactor.Parser"
        |> Callers.callers("all_functions", 1)
        |> Enum.sort_by(& &1.file)

      assert one.caller_module == ExFactor.Callers
      assert one.file == "lib/ex_factor/callers.ex"
      assert one.line == 9
    end

    test "when the module is invalid" do
      assert [] = Callers.callers("ExFactor.NotParser", "all_functions", 1)
    end

    test "when the function is invalid" do
      assert [] = Callers.callers("ExFactor.Parser", "not_a_function", 1)
    end

    test "when the arity doesn't match" do
      assert [] = Callers.callers("ExFactor.Parser", "all_functions", 7)
    end
  end
end
