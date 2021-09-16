defmodule ExFactor.CallersTest do
  use ExUnit.Case
  alias ExFactor.Callers

  describe "callers/1" do
    test "it should report callers of a module" do
      [one, _two, _three, _four, five] = Callers.callers(ExFactor.Parser)

      assert one.dependency_type == "(runtime)"
      assert one.filepath == "lib/ex_factor/callers.ex"
      assert five.filepath == "test/support/support.ex"
    end
  end
end
