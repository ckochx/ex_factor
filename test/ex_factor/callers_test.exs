defmodule ExFactor.CallersTest do
  use ExUnit.Case
  alias ExFactor.Callers

  describe "callers/1" do
    test "it should report callers of a module using a 0-arity trace function" do
      callers = Callers.callers(ExFactor.Parser, fn -> ExFactor.Support.Trace.trace_function() end)

      assert Enum.find(callers, fn {{path, _module}, _funs} -> path == "lib/ex_factor/evaluater.ex" end)
      assert support =Enum.find(callers, fn {{_path, module}, _funs} -> module == ExFactor.Evaluater end)

      {{_, _}, support_funs} = support

      assert Enum.find(support_funs, fn
        {_, _, _, ExFactor.Parser, :public_functions, _} -> true
        _ -> false
      end)
      assert Enum.find(support_funs, fn
        {_, _, _, ExFactor.Callers, :callers, _} -> true
        _ -> false
      end)
    end

    test "it uses the default tracer" do
      assert [] = Callers.callers(ExFactor.Parser, &Callers.trace_function/0)
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
