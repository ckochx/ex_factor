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
      # content = """
      # defmodule ExFactorSampleModule do
      #   @somedoc "This is somedoc"
      #   # a comment and no aliases
      #   _docp = "here's an arbitrary module underscore"
      #   @spec pub1(term()) :: term()
      #   def pub1(arg1) do
      #     :pub1_ok
      #   end
      # end
      # """

      # File.write("test/tmp/source_module.ex", content)
      # target_path = "test/tmp/target_module.ex"

      opts = [
        target: "ExFactor.Tmp.NeighborsMoveOut",
        module: "ExFactor.Neighbors",
        function: :wakl,
        arity: 3,
        dry_run: true
      ]

      argv = OptionParser.to_argv(opts)

      capture_io(fn -> Mix.Tasks.ExFactor.run(argv) end)
      |> IO.inspect(label: "ExFactor.run io")

      # file = File.read!(target_path)

      # assert file =~ "def pub1(arg1) do"
      # assert file =~ "defmodule ExFactor.NewMod do"
      # # includes additional attrs
      # assert file =~ "@spec pub1(term()) :: term()"
      # assert file =~ "@somedoc \"This is somedoc\""
      # # assert the added elements get flattened correctly
      # refute file =~ "[@somedoc \"This is somedoc\", "
      # # comments don't get moved
      # refute file =~ "# a comment and no aliases"
    end

    test "write a new file add a moduledoc comment" do
      content = """
      defmodule ExFactorSampleModule do

        def pub1(arg1) do
          :pub1_ok
        end
      end
      """

      File.write("test/tmp/source_module.ex", content)
      target_path = "test/tmp/target_module.ex"

      opts = [
        target_path: target_path,
        target: "ExFactor.NewMod",
        module: "ExFactorSampleModule",
        source_path: "test/tmp/source_module.ex",
        function: :pub1,
        arity: 1
      ]

      argv = OptionParser.to_argv(opts)
      capture_io(fn -> Mix.Tasks.ExFactor.run(argv) end)

      file = File.read!(target_path)
      assert file =~ "def pub1(arg1)"
      assert file =~ "@moduledoc \"This module created with ExFactor\""
    end

    test " with dry_run option, don't write the file." do
      content = """
      defmodule ExFactorSampleModule do
        @somedoc "This is somedoc"
        # a comment and no aliases
        _docp = "here's an arbitrary module underscore"
        @spec pub1(term()) :: term()
        def pub1(arg1) do
          :ok
        end
      end
      """

      File.write("test/tmp/source_module.ex", content)
      target_path = "test/tmp/target_module.ex"

      opts = [
        target_path: target_path,
        target: "ExFactor.NewMod",
        module: "ExFactorSampleModule",
        source_path: "test/tmp/source_module.ex",
        function: :pub1,
        arity: 1,
        dryrun: true
      ]

      argv = OptionParser.to_argv(opts)

      output = capture_io(fn -> Mix.Tasks.ExFactor.run(argv) end)

      # no new file gets written
      assert {:error, :enoent} = File.read(target_path)
      # assert output.file_contents
      assert output =~ "--dry_run changes to make"
      assert output =~ "ExFactor.NewMod"
    end

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
      content = """
      defmodule ExFactor.Module do
        def pub1(arg1) do
          ExFactorSampleModule.call_some_function(arg1)
        end
      end
      """

      File.write("lib/ex_factor/tmp/source_module.ex", content)

      opts = [
        target: "ExFactor.NewMod",
        module: "ExFactorSampleModule",
        moduleonly: true
      ]

      argv = OptionParser.to_argv(opts)

      capture_io(fn ->
        Mix.Tasks.ExFactor.run(argv)
      end)

      file = File.read!("lib/ex_factor/tmp/source_module.ex")
      assert file =~ "def pub1(arg1) do\n    NewMod.call_some_function(arg1)\n  end"
      assert file =~ "alias ExFactor.NewMod"
    end

  end
end
