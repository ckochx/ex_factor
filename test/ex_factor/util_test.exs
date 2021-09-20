defmodule ExFactor.UtilTest do
  use ExUnit.Case
  alias ExFactor.Util

  setup_all do
    File.mkdir_p("test/tmp")

    on_exit(fn ->
      File.rm_rf("test/tmp")
    end)
  end

  describe "module_to_string/1" do
    test "given a module name, convert it to a string, ensure the Elixir. prefix is not included" do
      refute Util.module_to_string(MyMod.SubMod.SubSubMod) =~ "Elixir."
      assert Util.module_to_string(MyMod.SubMod.SubSubMod) == "MyMod.SubMod.SubSubMod"
    end
  end
end
