defmodule ExFactorTest do
  use ExUnit.Case

  describe "refactor/1" do
    test "it refactors the functions into a new module, specified in opts" do
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

      ExFactor.refactor(opts)

      file = File.read!("lib/ex_factor/target_module.ex")
      assert file =~ "def(refactor1(arg1)) do"
      assert file =~ "def(refactor1([])) do"
      assert file =~ " @doc \"some docs\""
      assert file =~ "def pub_exists(arg_exists) do"

      file = File.read!("lib/ex_factor/source_module.ex")
      |> IO.inspect(label: "")
      refute file =~ "def refactor1(arg1) do"
      refute file =~ "def refactor1([]) do"

      # File.rm("lib/ex_factor/source_module.ex")
      # File.rm("lib/ex_factor/target_module.ex")
    end
  end
end
