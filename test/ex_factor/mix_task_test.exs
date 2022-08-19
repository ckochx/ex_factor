defmodule ExFactor.MixTaskTest do
  use ExUnit.Case
  import ExUnit.CaptureIO

  setup do
    File.mkdir_p("lib/ex_factor/tmp")

    on_exit(fn ->
      File.rm_rf("lib/ex_factor/tmp")
    end)
  end

  describe "mix task" do
    test "requires some options" do
      opts = [
        module: "ExFactorSampleModule",
        function: "pub1",
        arity: 1
      ]

      argv = OptionParser.to_argv(opts)

      assert_raise KeyError, "key :target not found in: #{inspect(opts)}", fn ->
        Mix.Tasks.ExFactor.run(argv)
      end
    end

    test "write a new file with the function" do
      opts = [
        target: "ExFactor.Tmp.NeighborsMoveOut",
        module: "ExFactor.Neighbors",
        function: :walk,
        arity: 3,
        dryrun: true,
        verbosde: true
      ]

      argv = OptionParser.to_argv(opts)

      run_message = capture_io(fn -> Mix.Tasks.ExFactor.run(argv) end)
      assert run_message =~ "Module: ExFactor.Tmp.NeighborsMoveOut"
      assert run_message =~ "Path: lib/ex_factor/tmp/neighbors_move_out.ex"
    end

    @tag :skip
    test "write multiple functions and their docs, into an existing module" do
      content = """
      defmodule ExFactor.Tmp.SourceModule do
        @somedoc "This is somedoc"
        @doc "this is some documentation for refactor1/1"
        def refactor1(arg1) do
          :ok
        end
        def refactor1([]) do
          :empty
        end
      end
      """

      File.write("test/tmp/source_module.ex", content)

      content = """
      defmodule ExFactor.Tmp.TargetModule do
        @moduledoc false
        @somedoc "This is somedoc TargetModule"
        @doc "some docs"
        def pub_exists(arg_exists) do
          :ok
        end
        def pub_exists(:error) do
          :error
        end
      end
      """

      target_path = "test/tmp/target_module.ex"
      File.write(target_path, content)

      opts = [
        target: "ExFactor.Tmp.TargetModule",
        module: "ExFactor.Tmp.SourceModule",
        target_path: target_path,
        source_path: "test/tmp/source_module.ex",
        function: :refactor1,
        arity: 1
      ]

      argv = OptionParser.to_argv(opts)

      capture_io(fn -> Mix.Tasks.ExFactor.run(argv) end)

      file = File.read!(target_path)
      assert file =~ "def refactor1(arg1) do"
      assert file =~ "def refactor1([]) do"
      assert file =~ " @doc \"some docs\""
    end

    setup do
      File.mkdir_p("lib/ex_factor/tmp")

      on_exit(fn ->
        File.rm_rf("lib/ex_factor/tmp")
      end)
    end

    test "with --moduleonly" do
      opts = [
        target: "ExFactor.Tmp.My.Neighbors.Moved",
        module: "ExFactor.Neighbors",
        moduleonly: true,
        dryrun: true
      ]

      argv = OptionParser.to_argv(opts)

      run_io = capture_io(fn ->
        Mix.Tasks.ExFactor.run(argv)
      end)
      assert run_io =~ " Module: Elixir.ExFactor.Extractor"
      assert run_io =~ "Path: lib/ex_factor/extractor.ex"
    end
  end
end
