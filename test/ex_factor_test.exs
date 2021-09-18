defmodule ExFactorTest do
  use ExUnit.Case

  setup_all do
    File.mkdir_p("lib/ex_factor/tmp")

    on_exit(fn ->
      File.rm_rf("lib/ex_factor/tmp")
    end)
  end

  describe "refactor/1" do
    test "it refactors the functions into a new module, specified in opts" do
      File.rm("lib/ex_factor/tmp/source_module.ex")
      File.rm("lib/ex_factor/tmp/target_module.ex")

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

      File.write("lib/ex_factor/tmp/source_module.ex", content)

      content = """
      defmodule ExFactor.Tmp.TargetModule do
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

      File.write("lib/ex_factor/tmp/target_module.ex", content)

      opts = [
        target_module: ExFactor.Tmp.TargetModule,
        source_module: ExFactor.Tmp.SourceModule,
        source_function: :refactor1,
        arity: 1
      ]

      results = ExFactor.refactor(opts)

      file = File.read!("lib/ex_factor/tmp/target_module.ex")
      assert file =~ "def(refactor1(arg1)) do"
      assert file =~ "def(refactor1([])) do"
      assert file =~ " @doc \"some docs\""
      assert file =~ "def pub_exists(arg_exists) do"

      file = File.read!("lib/ex_factor/tmp/source_module.ex")
      # |> IO.inspect(label: "")
      refute file =~ "def refactor1(arg1) do"
      refute file =~ "def refactor1([]) do"
      assert results == {:ok, :ok}
    end

    test "it returns the results of the dry_run changes" do
      File.rm("lib/ex_factor/tmp/source_module.ex")
      File.rm("lib/ex_factor/tmp/target_module.ex")

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

      File.write("lib/ex_factor/tmp/source_module.ex", content)

      content = """
      defmodule ExFactor.Tmp.TargetModule do
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

      File.write("lib/ex_factor/tmp/target_module.ex", content)

      opts = [
        target_module: ExFactor.Tmp.TargetModule,
        source_module: ExFactor.Tmp.SourceModule,
        source_function: :refactor1,
        arity: 1,
        dry_run: true
      ]

      {extract_contents, remove_contents} = ExFactor.refactor(opts)

      # assert that the original files are unchanged
      file = File.read!("lib/ex_factor/tmp/target_module.ex")
      refute file =~ "def(refactor1(arg1)) do"
      refute file =~ "def(refactor1([])) do"

      file = File.read!("lib/ex_factor/tmp/source_module.ex")
      assert file =~ "def refactor1(arg1) do"
      assert file =~ "def refactor1([]) do"

      # extract_contents |> IO.inspect(label: "")
      # remove_contents |> IO.inspect(label: "")
    end
  end
end
