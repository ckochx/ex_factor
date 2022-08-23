defmodule ExFactor.ExtractorTest do
  use ExUnit.Case
  alias ExFactor.Extractor

  setup do
    File.mkdir_p("test/tmp")
    File.mkdir_p("lib/ex_factor/tmp")

    on_exit(fn ->
      File.rm_rf("lib/ex_factor/tmp")
      File.rm_rf("test/tmp")
    end)
  end

  describe "emplace/1" do
    test "requires some options" do
      opts = [
        source_module: "ExFactorSampleModule",
        source_function: :pub1,
        arity: 1
      ]

      assert_raise KeyError, "key :target_module not found in: #{inspect(opts)}", fn ->
        Extractor.emplace(opts)
      end
    end

    test "noop when no matching fns found in source" do
      content = """
      defmodule ExFactorSampleModule do
        @spec pub1(term()) :: term()
        def pub1(arg1) do
          :pub1_ok
        end
      end
      """

      File.write("test/tmp/source_module.ex", content)

      opts = [
        target_module: "ExFactor.Test.NewModule",
        source_module: "ExFactorSampleModule",
        source_path: "test/tmp/source_module.ex",
        target_path: "test/tmp/target_module.ex",
        source_function: :pub2,
        arity: 1
      ]

      changes = Extractor.emplace(opts)

      assert changes.state == [:unchanged]
      assert changes.message == "function not detected in source."
      assert changes.file_contents == ""
      # file =
      assert_raise File.Error,
                   "could not read file \"test/tmp/target_module.ex\": no such file or directory",
                   fn ->
                     File.read!("test/tmp/target_module.ex")
                   end
    end

    test "create the dir path if necessary" do
      content = """
      defmodule ExFactorSampleModule do
        @somedoc "This is somedoc"
        # a comment and no aliases
        _docp = "here's an arbitrary module underscore"
        @spec pub1(term()) :: term()
        def pub1(arg1) do
          :pub1_ok
        end
      end
      """

      File.write("test/tmp/source_module.ex", content)

      opts = [
        target_module: "ExFactor.Test.NewModule",
        source_module: "ExFactorSampleModule",
        source_path: "test/tmp/source_module.ex",
        source_function: :pub1,
        arity: 1
      ]

      Extractor.emplace(opts)
      file = File.read!("lib/ex_factor/test/new_module.ex")

      assert file =~ "def pub1(arg1) do"
      assert file =~ "defmodule ExFactor.Test.NewModule do"
      # includes additional attrs
      assert file =~ "@spec pub1(term()) :: term()"
      assert file =~ "@somedoc \"This is somedoc\""
      # assert the added elements get flattened correctly
      refute file =~ "[@somedoc \"This is somedoc\", "
      # comments don't get moved
      refute file =~ "# a comment and no aliases"

      File.rm_rf("lib/ex_factor/test")
    end

    test "write a new file with the function" do
      content = """
      defmodule ExFactorSampleModule do
        @somedoc "This is somedoc"
        # a comment and no aliases
        _docp = "here's an arbitrary module underscore"
        @spec pub1(term()) :: term()
        def pub1(arg1) do
          :pub1_ok
        end
      end
      """

      File.write("test/tmp/source_module.ex", content)

      target_path = "test/tmp/target_module.ex"

      opts = [
        target_path: target_path,
        target_module: "ExFactor.NewMod",
        source_module: "ExFactorSampleModule",
        source_path: "test/tmp/source_module.ex",
        source_function: :pub1,
        arity: 1
      ]

      Extractor.emplace(opts)
      file = File.read!(target_path)

      assert file =~ "def pub1(arg1) do"
      assert file =~ "defmodule ExFactor.NewMod do"
      # includes additional attrs
      assert file =~ "@spec pub1(term()) :: term()"
      assert file =~ "@somedoc \"This is somedoc\""
      # assert the added elements get flattened correctly
      refute file =~ "[@somedoc \"This is somedoc\", "
      # comments don't get moved
      refute file =~ "# a comment and no aliases"
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
        target_module: "ExFactor.NewMod",
        source_module: "ExFactorSampleModule",
        source_path: "test/tmp/source_module.ex",
        source_function: :pub1,
        arity: 1
      ]

      Extractor.emplace(opts)

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
        target_module: "ExFactor.NewMod",
        source_module: "ExFactorSampleModule",
        source_path: "test/tmp/source_module.ex",
        source_function: :pub1,
        arity: 1,
        dry_run: true
      ]

      output = Extractor.emplace(opts)
      assert {:error, :enoent} = File.read(target_path)
      assert output.file_contents
      assert output.message == "--dry_run changes to make"
      assert output.module == "ExFactor.NewMod"
    end

    test "write a new file with the function, infer some defaults" do
      opts = [
        target_module: "ExFactor.Support.TargetModule",
        source_path: "test/support/example_five.ex",
        # target_path: "test/support/example_seven.ex",
        source_module: "ExFactor.Support.ExampleFive",
        source_function: :a_third_func,
        arity: 1,
        dry_run: true
      ]

      extracts = Extractor.emplace(opts)

      assert extracts.path == "lib/ex_factor/support/target_module.ex"
      assert extracts.module == "ExFactor.Support.TargetModule"
      assert extracts.file_contents =~ "defmodule ExFactor.Support.TargetModule do"
    end

    test "write a function, into an existing module" do
      opts = [
        target_module: "ExFactor.Support.ExampleSeven",
        source_path: "test/support/example_five.ex",
        target_path: "test/support/example_seven.ex",
        source_module: "ExFactor.Support.ExampleFive",
        source_function: :a_third_func,
        arity: 1,
        dry_run: true
      ]

      changes = Extractor.emplace(opts)

      file = changes.file_contents
      assert changes.module == "ExFactor.Support.ExampleSeven"
      assert changes.path == "test/support/example_seven.ex"
      assert file =~ "def a_third_func(path) do"
      assert file =~ "|> IO.inspect()"
    end

    test "write multiple functions and their docs, into a new module" do
      opts = [
        target_module: "ExFactor.Support.ExampleEight",
        source_path: "test/support/example_five.ex",
        target_path: "test/support/example_eight.ex",
        source_module: "ExFactor.Support.ExampleFive",
        source_function: :a_third_func,
        arity: 1,
        dry_run: true
      ]

      changes = Extractor.emplace(opts)

      file = changes.file_contents
      assert changes.module == "ExFactor.Support.ExampleEight"
      assert changes.path == "test/support/example_eight.ex"
      assert file =~ "def a_third_func(path) do"
      assert file =~ "|> IO.inspect()"
    end
  end
end
