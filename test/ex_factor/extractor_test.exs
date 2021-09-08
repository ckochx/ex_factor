defmodule ExFactor.ExtractorTest do
  use ExUnit.Case
  alias ExFactor.Extractor

  setup do
    File.rm("test/support/source_module.ex")
    File.rm("test/support/target_module.ex")
    :ok
  end

  test "write a new file with the function" do
    content = """
    defmodule ExFactorSampleModule do
      @somedoc "This is somedoc"
      # no aliases
      def pub1(arg1) do
        :ok
      end
    end
    """

    File.write("test/support/source_module.ex", content)

    # target_path = Macro.underscore(target_module)
    target_path = "test/support/target_module.ex"
    File.rm(target_path)

    opts = [
      target_path: target_path,
      target_module: ExFactor.NewMod,
      source_module: ExFactorSampleModule,
      source_path: "test/support/source_module.ex",
      source_function: :pub1,
      arity: 1
    ]

    path = Path.join([Mix.Project.app_path(), "lib", target_path <> ".ex"])
    Extractor.emplace(["test/support/source_module.ex"], opts)

    file = File.read!(target_path) |> IO.inspect(label: "target_path")
    assert file =~ "def(pub1(arg1))"
    assert file =~ "defmodule(ExFactor.NewMod) do"
  end

  test "write a new file with the function, infer some defaults" do
    content = """
    defmodule ExFactor.SourceModule do
      @somedoc "This is somedoc"
      # no aliases
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

    # path = Path.join([Mix.Project.app_path(), "lib", target_path <> ".ex"])
    Extractor.emplace(["lib/ex_factor/source_module.ex"], opts)

    file = File.read!("lib/ex_factor/target_module.ex")
    assert file =~ "def(pub1(arg1))"
    assert file =~ "defmodule(ExFactor.TargetModule) do"

    File.rm("lib/ex_factor/source_module.ex")
    File.rm("lib/ex_factor/target_module.ex")
  end
end
