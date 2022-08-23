defmodule ExFactorTest do
  use ExUnit.Case

  setup_all do
    File.mkdir_p("lib/ex_factor/tmp")

    on_exit(fn ->
      File.rm_rf("lib/ex_factor/tmp")
    end)
  end

  describe "path/1" do
    test "convert a module name to a file path" do
      assert "lib/test_module.ex" == ExFactor.path(TestModule)
    end

    test "convert a multi-atom module name to a file path" do
      assert "lib/my/test/module_name.ex" == ExFactor.path(My.Test.ModuleName)
    end
  end

  describe "refactor/1" do
    @tag :skip
    test "works with an imported fn" do
      opts = [
        source_module: "ExFactor.Support.ExampleSeven",
        source_path: "test/support/example_seven.ex",
        target_path: "test/support/example_six.ex",
        target_module: "ExFactor.Modified.ExampleSix",
        source_function: :all_funcs,
        arity: 1,
        dry_run: true
      ]
      %{additions: additions, changes: changes, removals: _} = _results = ExFactor.refactor(opts)
      additions   |> IO.inspect(label: "")
      assert additions.file_contents =~ "import ExFactor.Parser"
      changes |> IO.inspect(label: "")
    end

    test "it refactors the functions into a new module, specified in opts" do
      opts = [
        source_module: "ExFactor.Formatter",
        target_path: "test/support/example_six.ex",
        target_module: "ExFactor.Modified.ExampleSix",
        source_function: :format,
        arity: 2,
        dry_run: true
      ]
      %{additions: additions, changes: changes, removals: removals} = ExFactor.refactor(opts)

      assert removals.module == "ExFactor.Formatter"
      assert additions.module == "ExFactor.Modified.ExampleSix"
      assert additions.path == "test/support/example_six.ex"

      five = Enum.find(changes, &(&1.module ==  ExFactor.Support.ExampleFive))
      assert five.file_contents =~ "defdelegate format(args, opts \\\\ []), to: ExampleSix"
    end
  end

  describe "refactor_module/1" do
    test "it refactors the refs to a module name only" do
      opts = [
        target_module: "ExFactor.Tmp.My.Neughbors.Moved",
        source_module: "ExFactor.Neighbors",
        dry_run: true
      ]

      %{additions: additions, changes: [changes], removals: removals} =
        ExFactor.refactor_module(opts)

      assert additions == %ExFactor{}
      assert removals == %ExFactor{}

      assert %ExFactor{
               module: ExFactor.Extractor,
               path: "lib/ex_factor/extractor.ex",
               state: [:dry_run, :alias_added, :changed, :changed]
             } = changes
    end
  end
end
