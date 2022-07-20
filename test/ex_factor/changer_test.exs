defmodule ExFactor.ChangerTest do
  use ExUnit.Case
  alias ExFactor.Changer

  setup do
    File.rm_rf("lib/ex_factor/tmp")
    File.mkdir_p("lib/ex_factor/tmp")
    :ok
  end

  describe "change/1" do
    test "it finds all the callers of a module, function, and arity, and updates the calls to the new module" do
      content = """
        defmodule ExFactor.Tmp.SourceMod do
          @moduledoc "
          This is a multiline moduedoc
          "
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
        @moduledoc \"\"\"
        This is a multiline moduedoc.
        Its in the caller module
        \"\"\"
        alias ExFactor.Tmp.SourceMod
        alias ExFactor.Tmp.SourceMod.Other
        def pub1(arg_a) do
          SourceMod.refactor1(arg_a)
        end
        def pub2, do: Other

        def pub3(arg_a) do
          SourceMod.refactor1(arg_a)
        end
      end
      """

      File.write("lib/ex_factor/tmp/caller_module.ex", content)

      content = """
      defmodule ExFactor.Tmp.CallerTwoModule do
        alias ExFactor.Tmp.SourceMod
        def pub1(arg_a) do
          SourceMod.refactor1(arg_a)
        end
        def pub2, do: Enum
      end
      """

      File.write("lib/ex_factor/tmp/caller_two_module.ex", content)

      opts = [
        target_module: "ExFactor.Tmp.TargetModule",
        source_module: "ExFactor.Tmp.SourceMod",
        source_function: :refactor1,
        arity: 1
      ]

      changes = Changer.change(opts)

      caller = File.read!("lib/ex_factor/tmp/caller_module.ex")
      assert caller =~ "alias ExFactor.Tmp.TargetModule"
      # ensure we don't match dumbly
      assert caller =~ "alias ExFactor.Tmp.SourceMod.Other"
      refute caller =~ "alias ExFactor.Tmp.TargetModule.Other"
      # assert the alias doesn't get spliced into the moduledoc
      refute caller =~ "Its in the caller module\nalias ExFactor.Tmp.TargetModule\n  \""
      assert caller =~ "TargetModule.refactor1(arg_a)"
      # asser the function uses the alias
      refute caller =~ "ExFactor.Tmp.TargetModule.refactor1(arg_a)"
      assert caller =~ "def pub3(arg_a) do\n    TargetModule.refactor1(arg_a)"

      caller_two = File.read!("lib/ex_factor/tmp/caller_two_module.ex")
      assert caller_two =~ "alias ExFactor.Tmp.TargetModule"
      # ensure we don't match dumbly
      assert caller_two =~ "TargetModule.refactor1(arg_a)"
      # asser the function uses the alias
      refute caller_two =~ "ExFactor.Tmp.TargetModule.refactor1(arg_a)"

      assert Enum.find(changes, &(&1.path == "lib/ex_factor/tmp/caller_module.ex"))
      assert Enum.find(changes, &(&1.path == "lib/ex_factor/tmp/caller_two_module.ex"))
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

    test "add alias entry when the target alias is missing" do
      content = """
      defmodule ExFactor.Tmp.SourceMod do
        def refactor1(arg1) do
          {:ok, arg1}
        end
      end
      """

      File.write("lib/ex_factor/tmp/source_module.ex", content)

      content = """
      defmodule ExFactor.Tmp.CallerModule do
        alias ExFactor.Tmp.OtherModule
        def pub1(arg_a) do
          ExFactor.Tmp.SourceMod.refactor1(arg_a)
        end

        def pub2 do
          OtherModule
        end
      end
      """

      File.write("lib/ex_factor/tmp/caller_module.ex", content)

      opts = [
        target_module: "ExFactor.Tmp.TargetModule",
        source_module: "ExFactor.Tmp.SourceMod",
        source_function: "refactor1",
        arity: 1
      ]

      Mix.Tasks.Compile.Elixir.run([])

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

      Mix.Tasks.Compile.Elixir.run([])
      Changer.change(opts)
      caller = File.read!("lib/ex_factor/tmp/caller_module.ex")
      caller_list = String.split(caller, "\n")
      assert caller =~ "alias ExFactor.Tmp.TargetModule, as: TM"
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

      Mix.Tasks.Compile.Elixir.run([])

      Changer.change(opts)

      caller = File.read!("lib/ex_factor/tmp/caller_module.ex")
      assert caller =~ "alias ExFactor.Tmp.TargetModule"
      assert caller =~ "TargetModule.refactor1(arg_a)"
    end

    # same as no-function-found
    test "handles no modules found to change, messages correctly" do
      opts = [
        target_module: "ExFactor.Tmp.TargetMissing",
        source_module: "ExFactor.Tmp.SourceModMissing",
        source_function: :refactor1,
        arity: 1
      ]

      [change] = Changer.change(opts)
      assert change.message == "No additional references to source module: (ExFactor.Tmp.SourceModMissing) detected"
      assert change.state == [:unchanged]
    end

    test "updates a mod-fn-arity when the function is not aliased" do
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
        def pub1(arg_a) do
          ExFactor.Tmp.SourceMod.refactor1(arg_a)
        end
        def alias2, do: TheOtherModule
      end
      """

      File.write("lib/ex_factor/tmp/caller_module.ex", content)

      opts = [
        target_module: "ExFactor.Tmp.TargetModule",
        source_module: "ExFactor.Tmp.SourceMod",
        source_function: :refactor1,
        arity: 1
      ]

      Mix.Tasks.Compile.Elixir.run([])

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

      caller = File.read!("lib/ex_factor/tmp/caller_module.ex")

      refute caller =~ "alias ExFactor.Tmp.TargetModule"
      refute caller =~ "TargetModule.refactor1(arg_a)"

      assert Enum.find(change_map.state, fn el ->
               String.match?(Atom.to_string(el), ~r/alias_/)
             end)

      # change_map.state == [:dry_run, :alias_changed, :changed]
      assert change_map.message == "--dry_run changes to make"
    end

    # functions to fill in
    test "update the alternate alias style: alias Foo.{Bar, Baz, Biz}" do
    end

    test "matches the arity" do
    end

    test "change import fns" do
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
        alias ExFactor.Tmp.SourceMod
        import SourceMod
        def pub1(arg_a) do
          refactor1(arg_a)
        end
      end
      """

      File.write("lib/ex_factor/tmp/caller_module.ex", content)

      opts = [
        target_module: "ExFactor.Tmp.TargetModule",
        source_module: "ExFactor.Tmp.SourceMod",
        source_function: "refactor1",
        arity: 1
      ]

      [change_map] = Changer.change(opts)
      caller = File.read!("lib/ex_factor/tmp/caller_module.ex")

      assert caller =~ "import ExFactor.Tmp.TargetModule"
      assert caller =~ " refactor1(arg_a)"
      assert change_map.state == [:import_added]
      assert change_map.message == "changes made"
    end
  end
end
