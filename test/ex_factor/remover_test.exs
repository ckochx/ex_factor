defmodule ExFactor.RemoverTest do
  use ExUnit.Case
  alias ExFactor.Remover

  setup_all do
    File.mkdir_p("test/tmp")

    on_exit(fn ->
      File.rm_rf("test/tmp")
    end)
  end

  describe "remove/1" do
    test "remove the given function from the source module" do
      content = """
      defmodule ExFactorSampleModule do
        @somedoc "This is somedoc"
        # a comment and no aliases
        _docp = "here's an arbitrary module underscore"
        def pub1(arg1) do
          :ok
        end
      end
      """

      File.write("test/tmp/source_module.ex", content)
      source_path = "test/tmp/source_module.ex"

      opts = [
        source_module: ExFactorSampleModule,
        source_path: "test/tmp/source_module.ex",
        source_function: :pub1,
        arity: 1
      ]

      Remover.remove(opts)

      file = File.read!(source_path)
      assert file =~ "defmodule ExFactorSampleModule do"
      assert file =~ "_docp = \"here's an arbitrary module underscore"
      refute file =~ "def pub1(arg1) do"
      File.rm("test/support/source_module.ex")
    end

    test "it rewrites the source file and removes code blocks" do
      module = """
      defmodule ExFactorSampleModule do
        @somedoc "This is somedoc"
        # comments get dropped
        @doc "
        multiline
        documentation for pub1
        "
        @spec pub1(term()) :: term()
        def pub1(arg1) do
          :ok
        end
        _docp = "arbitrary module-level elem"
        defp priv1(arg1) do
          :ok
        end

        def pub2(arg1)
          do
            :ok
          end

      end
      """

      File.write("test/tmp/source_module.ex", module)
      opts = [
        source_module: ExFactorSampleModule,
        source_path: "test/tmp/source_module.ex",
        source_function: :pub1,
        arity: 1
      ]
      Remover.remove(opts)

      updated_file = File.read!("test/tmp/source_module.ex")
      refute updated_file =~ "def pub1(arg1) do"
      assert updated_file =~ "Function: pub1/1 removed by ExFactor"
      assert updated_file =~ "# @spec: pub1/1 removed by ExFactor"
      # it removes specs too
      refute updated_file =~ "@spec pub1(term()) :: term()"
    end

    test "takes a dry_run option to only report intended changes" do
      module = """
      defmodule ExFactorSampleModule do
        @somedoc "This is somedoc"
        # comments get dropped
        @doc "
        multiline
        documentation for pub1
        "
        @spec pub1(term()) :: term()
        def pub1(arg1) do
          :ok
        end
        _docp = "arbitrary module-level elem"
        defp priv1(arg1) do
          :ok
        end

        def pub2(arg1)
          do
            :ok
          end

      end
      """

      File.write("test/tmp/source_module.ex", module)
      opts = [
        dry_run: true,
        source_module: ExFactorSampleModule,
        source_path: "test/tmp/source_module.ex",
        source_function: :pub1,
        arity: 1
      ]
      changes = Remover.remove(opts)

      unchanged_file = File.read!("test/tmp/source_module.ex")
      assert unchanged_file =~ "def pub1(arg1) do"
      refute unchanged_file =~ "Function: pub1/1 removed by ExFactor"
      assert unchanged_file =~ "@spec pub1(term()) :: term()"

      assert changes =~ "Function: pub1/1 removed by ExFactor"
      refute changes =~ "@spec pub1(term()) :: term()"
      refute changes =~ "def pub1(arg1) do"
    end

  end
end
