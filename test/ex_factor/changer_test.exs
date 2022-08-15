defmodule ExFactor.ChangerTest do
  use ExUnit.Case
  alias ExFactor.Changer

  describe "change/1" do
    test "it renames all the instances of a module" do
      opts = [
        target_module: "ExFactor.Modified.Parser",
        source_module: "ExFactor.Parser",
        dry_run: true
      ]

      changes = Changer.change(opts)

      assert %ExFactor{} = change = Enum.find(changes, &(&1.module == ExFactor.Remover))
      assert [{ExFactor.Remover, _bin}] = Code.compile_string(change.file_contents)
    end

    test "it finds all the callers of a module, function, and arity, and updates the calls to the new module" do
      opts = [
        target_module: "ExFactor.Modified.Parser",
        source_module: "ExFactor.Parser",
        source_function: "read_file",
        arity: 1,
        dry_run: true
      ]

      changes = Changer.change(opts)

      changed_modules = changes
      |> Enum.map(& &1.module)
      |> Enum.sort()

      assert changed_modules == [ExFactor.Extractor, ExFactor.Remover]

      assert %ExFactor{} = change = Enum.find(changes, &(&1.module == ExFactor.Remover))
      assert [{ExFactor.Remover, _bin}] = Code.compile_string(change.file_contents)
    end

    test "only add alias entry if it's missing" do
      opts = [
        target_module: "ExFactor.Modified.NotCallers",
        source_module: "ExFactor.Callers",
        # source_function: "read_file",
        # arity: 1,
        dry_run: true
      ]

      changes = Changer.change(opts)
      assert %ExFactor{} = change = Enum.find(changes, &(&1.module == ExFactor.Support.ExampleTwo))
      assert change.file_contents =~ "alias ExFactor.Modified.NotCallers"
      assert change.file_contents =~ " NotCallers.callers(mod)"
    end

    test "handle alias exists with :as" do
      opts = [
        target_module: "ExFactor.Modified.NotMyParser",
        source_module: "ExFactor.Parser",
        dry_run: true
      ]

      changes = Changer.change(opts)
      assert %ExFactor{} = change = Enum.find(changes, &(&1.module == ExFactor.Support.ExampleTwo))

      assert change.file_contents =~ "alias ExFactor.Modified.NotMyParser"
      assert change.file_contents =~ "P.all_functions("
      assert change.file_contents =~ " NotMyParser, as: P"
    end

    test "it finds all the callers of a module by an alias, function, and arity, and updates the calls to the new module " do
      opts = [
        target_module: "ExFactor.Modified.OtherCallers",
        source_module: "ExFactor.Callers",
        source_function: "callers",
        arity: 1,
        dry_run: true
      ]

      changes = Changer.change(opts)
      assert %ExFactor{} = change = Enum.find(changes, &(&1.module == ExFactor.Support.ExampleOne))
      # change.file_contents |> IO.inspect(label: "")
      assert change.file_contents =~ "OtherCallers.callers(mod)"
    end

    # same as no-function-found
    test "handles no modules found to change, messages correctly" do
      opts = [
        target_module: "ExFactor.Tmp.TargetMissing",
        source_module: "ExFactor.Tmp.SourceModMissing",
        source_function: :refactor1,
        arity: 1
      ]

      [change] = Changer.change(opts)

      assert change.message ==
               "No additional references to source module: (ExFactor.Tmp.SourceModMissing) detected"

      assert change.state == [:unchanged]
    end

    test "updates a mod-fn-arity when the function is not aliased" do
      opts = [
        target_module: "ExFactor.Modified.SomeNewCallers",
        source_module: "ExFactor.Callers",
        source_function: "callers",
        arity: 1,
        dry_run: true
      ]

      changes = Changer.change(opts)
      assert %ExFactor{} = change = Enum.find(changes, &(&1.module == ExFactor.Support.ExampleTwo))
      # change.file_contents |> IO.inspect(label: "")
      assert change.file_contents =~ "SomeNewCallers.callers(mod)"
      assert change.file_contents =~ "alias ExFactor.Modified.SomeNewCallers"
    end

    # functions to fill in
    test "update the alternate alias style: alias Foo.{Bar, Baz, Biz}" do
    end

    test "matches the arity" do
    end

    test "change import fns" do
      opts = [
        target_module: "ExFactor.Modified.SomeNewParser",
        source_module: "ExFactor.Parser",
        dry_run: true
      ]

      changes = Changer.change(opts)
      assert %ExFactor{} = change = Enum.find(changes, &(&1.module == ExFactor.Support.ExampleFive))
      # change.file_contents |> IO.inspect(label: "")
      assert change.file_contents =~ "alias ExFactor.Modified.SomeNewParser"
      assert change.file_contents =~ "import SomeNewParser"
      assert change.file_contents =~ "import Parser"
      assert change.file_contents =~ "def all_funcs(input), do: all_functions(input)"
    end
  end
end
