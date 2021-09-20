defmodule ExFactor.ChangerTest do
  use ExUnit.Case
  alias ExFactor.Changer

  setup_all do
    File.mkdir_p("lib/ex_factor/tmp")

    on_exit(fn ->
      File.rm_rf("lib/ex_factor/tmp")
    end)
  end

  describe "change/1" do
    test "it finds all the callers of a module, function, and arity, and updates the calls to the new module " do
      content = """
      defmodule ExFactor.Tmp.SourceMod do
        @moduledoc "This is moduedoc"
        @doc "this is some documentation for refactor1/1"
        def refactor1([]) do
          :empty
        end
        def refactor1(arg1) do
          {:ok, arg1}
        end
      end
      """

      File.write("lib/ex_factor/tmp/source_module.ex", content)

      content = """
      defmodule ExFactor.Tmp.CallerModule do
        alias ExFactor.Tmp.SourceMod
        def pub1(arg_a) do
          SourceMod.refactor1(arg_a)
        end
      end
      """

      File.write("lib/ex_factor/tmp/caller_module.ex", content)

      opts = [
        target_module: "ExFactor.Tmp.TargetModule",
        source_module: "ExFactor.Tmp.SourceMod",
        source_function: :refactor1,
        arity: 1
      ]

      Changer.change(opts)

      caller = File.read!("lib/ex_factor/tmp/caller_module.ex")
      assert caller =~ "alias ExFactor.Tmp.TargetModule"
      assert caller =~ "TargetModule.refactor1(arg_a)"
    end

    test "only add alias entry if it's missing" do
      content = """
      defmodule ExFactor.Tmp.SourceMod do
        @moduledoc "This is moduedoc"
        @doc "this is some documentation for refactor1/1"
        def refactor1([]) do
          :empty
        end
        def refactor1(arg1) do
          {:ok, arg1}
        end
      end
      """

      File.write("lib/ex_factor/tmp/source_module.ex", content)

      content = """
      defmodule ExFactor.Tmp.CallerModule do
        alias ExFactor.Tmp.SourceMod
        alias ExFactor.Tmp.TargetModule
        def pub1(arg_a) do
          SourceMod.refactor1(arg_a)
        end
        def alias2, do: TargetModule
      end
      """

      File.write("lib/ex_factor/tmp/caller_module.ex", content)

      opts = [
        target_module: "ExFactor.Tmp.TargetModule",
        source_module: "ExFactor.Tmp.SourceMod",
        source_function: :refactor1,
        arity: 1
      ]

      Changer.change(opts)

      caller = File.read!("lib/ex_factor/tmp/caller_module.ex")

      caller_list = String.split(caller, "\n")
      assert caller =~ "alias ExFactor.Tmp.TargetModule"
      assert caller =~ "TargetModule.refactor1(arg_a)"

      assert 1 ==
               Enum.count(caller_list, fn el ->
                 el =~ "alias ExFactor.Tmp.TargetModule"
               end)
    end

    test "handle alias exists with :as" do
      content = """
      defmodule ExFactor.Tmp.SourceMod do
        @moduledoc "This is moduedoc"
        @doc "this is some documentation for refactor1/1"
        def refactor1([]) do
          :empty
        end
        def refactor1(arg1) do
          {:ok, arg1}
        end
      end
      """

      File.write("lib/ex_factor/tmp/source_module.ex", content)

      content = """
      defmodule ExFactor.Tmp.CallerModule do
        alias ExFactor.Tmp.SourceMod
        alias ExFactor.Tmp.TargetModule, as: TM
        def pub1(arg_a) do
          SourceMod.refactor1(arg_a)
        end
        def alias2, do: TM
      end
      """

      File.write("lib/ex_factor/tmp/caller_module.ex", content)

      opts = [
        target_module: "ExFactor.Tmp.TargetModule",
        source_module: "ExFactor.Tmp.SourceMod",
        source_function: :refactor1,
        arity: 1
      ]

      Changer.change(opts)

      caller = File.read!("lib/ex_factor/tmp/caller_module.ex")

      caller_list = String.split(caller, "\n")
      assert caller =~ "alias ExFactor.Tmp.TargetModule"
      assert caller =~ "TM.refactor1(arg_a)"

      assert 1 ==
               Enum.count(caller_list, fn el ->
                 el =~ "alias ExFactor.Tmp.TargetModule"
               end)
    end

    test "it finds all the callers of a module by an alias, function, and arity, and updates the calls to the new module " do
      content = """
      defmodule ExFactor.Tmp.SourceMod do
        def refactor1(_arg1, _opt2 \\\\ []) do
          :ok
        end
      end
      """

      File.write("lib/ex_factor/tmp/source_module.ex", content)

      content = """
      defmodule ExFactor.Tmp.CallerModule do
        alias ExFactor.Tmp.SourceMod, as: SM
        def pub1(arg_a) do
          SM.refactor1(arg_a)
        end
      end
      """

      File.write("lib/ex_factor/tmp/caller_module.ex", content)

      opts = [
        target_module: "ExFactor.Tmp.TargetModule",
        source_module: "ExFactor.Tmp.SourceMod",
        source_function: :refactor1,
        arity: 1
      ]

      Changer.change(opts)

      caller = File.read!("lib/ex_factor/tmp/caller_module.ex")
      assert caller =~ "alias ExFactor.Tmp.TargetModule"
      assert caller =~ "TargetModule.refactor1(arg_a)"
    end

    test "matches the arity" do
    end

    test "changes multiple functions" do
    end

    test "takes a dry_run argument and doesn't update the files" do
      content = """
      defmodule ExFactor.Tmp.SourceMod do
        def refactor1(_arg1, _opt2 \\\\ []) do
          :ok
        end
      end
      """

      File.write("lib/ex_factor/tmp/source_module.ex", content)

      content = """
      defmodule ExFactor.Tmp.CallerModule do
        alias ExFactor.Tmp.SourceMod, as: SM
        def pub1(arg_a) do
          SM.refactor1(arg_a)
        end
      end
      """

      File.write("lib/ex_factor/tmp/caller_module.ex", content)

      opts = [
        target_module: "ExFactor.Tmp.TargetModule",
        source_module: "ExFactor.Tmp.SourceMod",
        source_function: :refactor1,
        dry_run: true,
        arity: 1
      ]

      [change_map] = Changer.change(opts)
      # |> IO.inspect(label: "")

      caller = File.read!("lib/ex_factor/tmp/caller_module.ex")

      refute caller =~ "alias ExFactor.Tmp.TargetModule"
      refute caller =~ "TargetModule.refactor1(arg_a)"
      assert change_map.state == [:dry_run, :changed]
      assert change_map.message == "--dry_run changes to make"
    end
  end
end
