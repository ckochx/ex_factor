defmodule ExFactor.CallersTest do
  use ExUnit.Case
  alias ExFactor.Callers

  describe "callers/2" do
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

  describe "callers/4" do
    test "it should report callers of a module" do
      callers = Callers.callers(ExFactor.Parser, :all_functions, 1)
      assert Enum.find(callers, fn {{path, _module}, _funs} -> path == "lib/ex_factor/remover.ex" end)
      assert Enum.find(callers, fn {{_path, module}, _funs} -> module == ExFactor.Remover end)
    end

    test "it converts strings to atoms" do
      callers = Callers.callers("ExFactor.Parser", "all_functions", 1)
      assert Enum.find(callers, fn {{path, _module}, _funs} -> path == "lib/ex_factor/remover.ex" end)
      assert Enum.find(callers, fn {{_path, module}, _funs} -> module == ExFactor.Remover end)
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
