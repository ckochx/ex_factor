defmodule ExFactor.ExtractorTest do
  use ExUnit.Case
  alias ExFactor.Extractor

  setup_all do
    File.mkdir_p("test/tmp")

    on_exit(fn ->
      File.rm_rf("test/tmp")
    end)
  end

  describe "emplace/1" do
    test "requires some options" do
      opts = [
        source_module: ExFactorSampleModule,
        source_function: :pub1,
        arity: 1
      ]

      assert_raise KeyError, "key :target_module not found in: #{inspect(opts)}", fn -> Extractor.emplace(opts) end
    end

    test "write a new file with the function" do
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
      File.rm(target_path)

      opts = [
        target_path: target_path,
        target_module: ExFactor.NewMod,
        source_module: ExFactorSampleModule,
        source_path: "test/tmp/source_module.ex",
        source_function: :pub1,
        arity: 1
      ]

      Extractor.emplace(opts)

      file = File.read!(target_path)
      assert file =~ "def(pub1(arg1))"
      assert file =~ "defmodule(ExFactor.NewMod) do"
      # includes additional attrs
      assert file =~ "@spec(pub1(term()) :: term())"
      assert file =~ "@somedoc(\"This is somedoc\")"
      # assert the added elements get flattened correctly
      refute file =~ "[@somedoc(\"This is somedoc\"), "
      # comments don't get moved
      refute file =~ "# a comment and no aliases"
      File.rm("test/tmp/source_module.ex")
      File.rm("test/tmp/target_module.ex")
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
      File.rm(target_path)

      opts = [
        target_path: target_path,
        target_module: ExFactor.NewMod,
        source_module: ExFactorSampleModule,
        source_path: "test/tmp/source_module.ex",
        source_function: :pub1,
        arity: 1,
        dry_run: true
      ]

      output = Extractor.emplace(opts)
      assert {:error, :enoent} = File.read(target_path)
      assert output =~ "defmodule(ExFactor.NewMod) do"
    end

    test "write a new file with the function, infer some defaults" do
      File.rm("lib/ex_factor/source_module.ex")
      File.rm("lib/ex_factor/target_module.ex")

      content = """
      defmodule ExFactor.SourceModule do
        @somedoc "This is somedoc"
        def pub1(arg1) do
          :ok
        end
      end
      """

      File.write("lib/ex_factor/source_module.ex", content)

      opts = [
        target_module: ExFactor.TargetModule,
        source_module: ExFactor.SourceModule,
        source_function: :pub1,
        arity: 1
      ]

      Extractor.emplace(opts)

      file = File.read!("lib/ex_factor/target_module.ex")
      assert file =~ "def(pub1(arg1))"
      assert file =~ "defmodule(ExFactor.TargetModule) do"

      File.rm("lib/ex_factor/source_module.ex")
      File.rm("lib/ex_factor/target_module.ex")
    end

    test "write the function into an existing module" do
      File.rm("lib/ex_factor/source_module.ex")
      File.rm("lib/ex_factor/target_module.ex")

      content = """
      defmodule ExFactor.SourceModule do
        @somedoc "This is somedoc"
        def refactor1(arg1) do
          :ok
        end
      end
      """

      File.write("test/tmp/source_module.ex", content)

      content = """
      defmodule ExFactor.TargetModule do
        @somedoc "This is somedoc TargetModule"
        # this is a comment, it will get elided
        def pub_exists(arg_exists) do
          :ok
        end
      end
      """

      File.write("lib/ex_factor/target_module.ex", content)

      opts = [
        target_module: ExFactor.TargetModule,
        source_module: ExFactor.SourceModule,
        source_function: :refactor1,
        arity: 1
      ]

      Extractor.emplace(opts)

      file = File.read!("lib/ex_factor/target_module.ex")
      assert file =~ "def(refactor1(arg1)) do"
      assert file =~ "def pub_exists(arg_exists) do"
      assert file =~ "defmodule ExFactor.TargetModule do"

      File.rm("lib/ex_factor/source_module.ex")
      File.rm("lib/ex_factor/target_module.ex")
    end

    test "write multiple functions, into an existing module" do
      File.rm("lib/ex_factor/source_module.ex")
      File.rm("lib/ex_factor/target_module.ex")

      content = """
      defmodule ExFactor.SourceModule do
        @somedoc "This is somedoc"
        def refactor1(arg1) do
          :ok
        end
      end
      """

      File.write("lib/ex_factor/source_module.ex", content)

      content = """
      defmodule ExFactor.TargetModule do
        @somedoc "This is somedoc TargetModule"
        # this is a comment, it will get elided
        def pub_exists(arg_exists) do
          :ok
        end
        def pub_exists(:error) do
          :error
        end
      end
      """

      File.write("lib/ex_factor/target_module.ex", content)

      opts = [
        target_module: ExFactor.TargetModule,
        source_module: ExFactor.SourceModule,
        source_function: :refactor1,
        arity: 1
      ]

      Extractor.emplace(opts)

      file = File.read!("lib/ex_factor/target_module.ex")
      assert file =~ "def(refactor1(arg1)) do"
      assert file =~ "def pub_exists(arg_exists) do"
      assert file =~ "def pub_exists(:error) do"
      assert file =~ "defmodule ExFactor.TargetModule do"

      File.rm("lib/ex_factor/source_module.ex")
      File.rm("lib/ex_factor/target_module.ex")
    end

    test "write multiple functions and their docs, into an existing module" do
      File.rm("lib/ex_factor/source_module.ex")
      File.rm("lib/ex_factor/target_module.ex")

      content = """
      defmodule ExFactor.SourceModule do
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

      File.write("lib/ex_factor/source_module.ex", content)

      content = """
      defmodule ExFactor.TargetModule do
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

      File.write("lib/ex_factor/target_module.ex", content)

      opts = [
        target_module: ExFactor.TargetModule,
        source_module: ExFactor.SourceModule,
        source_function: :refactor1,
        arity: 1
      ]

      Extractor.emplace(opts)

      file = File.read!("lib/ex_factor/target_module.ex")
      |> IO.inspect(label: "")
      assert file =~ "def(refactor1(arg1)) do"
      assert file =~ "def(refactor1([])) do"
      assert file =~ " @doc \"some docs\""

      File.rm("lib/ex_factor/source_module.ex")
      File.rm("lib/ex_factor/target_module.ex")
    end
  end
end
