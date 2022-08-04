defmodule ExFactor.EvaluaterTest do
  use ExUnit.Case
  alias ExFactor.Evaluater

  describe "modules_to_refactor/1" do
    @tag :skip
    test "it should report callers of a module function" do
      assert ["test/support/support.ex" | _] =
               Evaluater.modules_to_refactor(ExFactor.Parser, :all_functions, 1)
    end
  end
end
