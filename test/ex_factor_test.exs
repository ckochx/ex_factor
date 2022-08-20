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
    test "works with another one-liner fn" do
      opts = [
        source_module: "ExFactor.Support.ExampleSeven",
        source_path: "test/support/example_seven.ex",
        target_path: "test/support/example_six.ex",
        target_module: "ExFactor.Modified.ExampleSix",
        source_function: :all_functions,
        arity: 1,
        dry_run: true
      ]
      %{additions: _, changes: _, removals: _} = _results = ExFactor.refactor(opts)
    end

    test "works with a one-liner fn" do
      opts = [
        source_module: "ExFactor.Formatter",
        target_path: "test/support/example_six.ex",
        target_module: "ExFactor.Modified.ExampleSix",
        source_function: :format,
        arity: 2,
        dry_run: true
      ]
      %{additions: additions, changes: changes, removals: removals} = ExFactor.refactor(opts)
      # |> IO.inspect(label: "changes")

      assert removals.module == "ExFactor.Formatter"
      assert additions.module == "ExFactor.Modified.ExampleSix"
      assert additions.path == "test/support/example_six.ex"

      five = Enum.find(changes, &(&1.module ==  ExFactor.Support.ExampleFive))
      assert five.file_contents =~ "defdelegate format(args, opts \\\\ []), to: ExampleSix"
    end

    test "it refactors the functions into a new module, specified in opts" do
      File.rm("lib/ex_factor/tmp/source_module.ex")
      File.rm("lib/ex_factor/tmp/target_module.ex")

      content = """
      defmodule ExFactor.Tmp.SourceModule do
        @doc "this is some documentation for refactor1/1"
        def refactor1([]) do
          :empty
        end
        def refactor1(arg1) do
          arg1
        end
      end
      """

      File.write("lib/ex_factor/tmp/source_module.ex", content)

      content = """
      defmodule ExFactor.Tmp.TargetModule do
        @doc "some docs"
        def pub_exists(:error) do
          :error
        end
        def pub_exists(arg_exists) do
          arg_exists
        end
      end
      """

      File.write("lib/ex_factor/tmp/target_module.ex", content)

      opts = [
        target_module: "ExFactor.Tmp.TargetModule",
        source_module: "ExFactor.Tmp.SourceModule",
        source_function: :refactor1,
        arity: 1
      ]

      %{additions: _, changes: _, removals: _} = _results = ExFactor.refactor(opts)

      file = File.read!("lib/ex_factor/tmp/target_module.ex")
      assert file =~ "def refactor1(arg1) do"
      assert file =~ "def refactor1([]) do"
      assert file =~ " @doc \"some docs\""
      assert file =~ "def pub_exists(arg_exists) do"

      file = File.read!("lib/ex_factor/tmp/source_module.ex")
      refute file =~ "def refactor1(arg1) do"
      refute file =~ "def refactor1([]) do"
    end

    test "it skips formatting when specified in opts" do
      File.rm("lib/ex_factor/tmp/source_module.ex")
      File.rm("lib/ex_factor/tmp/target_module.ex")

      content = """
      defmodule ExFactor.Tmp.SourceModule do
        @doc "this is some documentation for refactor1/1"
        def refactor1([]) do
          :empty
        end
        def refactor1(arg1) do
          arg1
        end
      end
      """

      File.write("lib/ex_factor/tmp/source_module.ex", content)

      content = """
      defmodule ExFactor.Tmp.TargetModule do
           @doc "some docs"
        def pub_exists(:error) do
          :error
        end
        def pub_exists(arg_exists) do
          arg_exists
        end
      end
      """

      File.write("lib/ex_factor/tmp/target_module.ex", content)

      opts = [
        target_module: "ExFactor.Tmp.TargetModule",
        source_module: "ExFactor.Tmp.SourceModule",
        source_function: :refactor1,
        arity: 1,
        format: false
      ]

      %{additions: _, changes: _, removals: _} = _results = ExFactor.refactor(opts)

      file = File.read!("lib/ex_factor/tmp/target_module.ex")

      assert file =~ "\ndef refactor1(arg1) do"
      assert file =~ "defmodule ExFactor.Tmp.TargetModule do\n     @doc \"some docs\""
    end

    test "it returns the results of the dry_run changes" do
      File.rm("lib/ex_factor/tmp/source_module.ex")
      File.rm("lib/ex_factor/tmp/target_module.ex")

      content = """
      defmodule ExFactor.Tmp.SourceModule do
        @doc "this is some documentation for refactor1/1"
        def refactor1([]) do
          :empty
        end
        def refactor1(arg1) do
          arg1
        end
      end
      """

      File.write("lib/ex_factor/tmp/source_module.ex", content)

      content = """
      defmodule ExFactor.Tmp.TargetModule do
        @someattr "This is somedoc TargetModule"
        @doc "some docs"
        def pub_exists(:error) do
          :error
        end
        def pub_exists(arg_exists) do
          _ = @someattr
          arg_exists
        end
      end
      """

      File.write("lib/ex_factor/tmp/target_module.ex", content)

      opts = [
        target_module: "ExFactor.Tmp.TargetModule",
        source_module: "ExFactor.Tmp.SourceModule",
        source_function: :refactor1,
        arity: 1,
        dry_run: true
      ]

      %{additions: _, changes: _, removals: _} = ExFactor.refactor(opts)

      # assert that the original files are unchanged
      file = File.read!("lib/ex_factor/tmp/target_module.ex")
      refute file =~ "def refactor1(arg1) do"
      refute file =~ "def refactor1([]) do"

      file = File.read!("lib/ex_factor/tmp/source_module.ex")
      assert file =~ "def refactor1(arg1) do"
      assert file =~ "def refactor1([]) do"
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
