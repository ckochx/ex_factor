defmodule ExFactor.ParserTest do
  use ExUnit.Case
  alias ExFactor.Parser

  setup_all do
    File.mkdir_p("test/tmp")

    on_exit(fn ->
      File.rm_rf("test/tmp")
    end)
  end

  describe "public_functions/1" do
    test "it reports public fns for a filepath" do
      content = """
      defmodule ExFactorSampleModule do
        @somedoc "This is somedoc"
        # no aliases
        def pub1(arg1) do
          :ok
        end
      end
      """

      File.write("test/tmp/test_module.ex", content)
      {_ast, [f1]} = Parser.public_functions("test/tmp/test_module.ex")

      assert f1.name == :pub1
      assert f1.arity == 1
    end

    test "it should report public fns and their arity" do
      {_ast, [f1]} =
        """
        defmodule ExFactorSampleModule do
          @somedoc "This is somedoc"
          # no aliases
          def pub1(arg1) do
            :ok
          end
        end
        """
        |> Code.string_to_quoted()
        |> Parser.public_functions()

      assert f1.name == :pub1
      assert f1.arity == 1
    end

    test "it should report public fns with start and end lines" do
        content = """
        defmodule ExFactorSampleModule do
          @somedoc "This is somedoc"
          # no aliases
          def pub1(arg1) do
            :ok
          end
        end
        """
        # |> Code.string_to_quoted()

      File.write("test/tmp/other_module.ex", content)

      {_ast, [f1]} = Parser.public_functions("test/tmp/other_module.ex")
      assert f1.name == :pub1
      assert f1.arity == 1
      assert f1.start_line == 4
      assert f1.end_line == 6
    end

    test "it should report specs with start and end lines" do
      module = """
        defmodule ExFactorSampleModule do
          @somedoc "This is somedoc"
          # no aliases
          @spec pub1(term()) :: term()
          def pub1(arg1) do
            :ok
          end
        end
        """

      File.write("test/tmp/other_module.ex", module)

      {_ast, [f1, f2]} = Parser.public_functions("test/tmp/other_module.ex")
      assert f1.name == :pub1
      assert f1.arity == 1
      assert f1.start_line == 5
      assert f1.end_line == 7

      assert f2.name == :pub1
      assert f2.defn == "@spec"
      assert f2.arity == 1
      assert f2.start_line == 4
      assert f2.end_line == 4
    end

    test "it should report TWO public fns" do
      content =
        """
        defmodule ExFactorSampleModule do
          @somedoc "This is somedoc"
          # no aliases
          def pub1(arg1) do
            :ok
          end

          def pub2(arg2)
            do
              #comment
              :yes
            end

          defp pub3(arg3) do
            :private
          end
        end
        """
      File.write("test/tmp/other_module.ex", content)

      {_ast, [f1, f2]} = Parser.public_functions("test/tmp/other_module.ex")

      assert f2.name == :pub1
      assert f2.start_line == 4
      assert f2.end_line == 6
      assert f1.name == :pub2
      assert f1.start_line == 8
      assert f1.end_line == 12
    end

    # @tag :skip
    test "it should handle when clauses" do
      content =
        """
        defmodule ExFactorSampleModule do
          @somedoc "This is somedoc"
          # no aliases
          def pub1(arg1) do
            :ok
          end

          def pub2(arg2) when is_map(arg2) and not is_nil(arg2)
            do
              #comment
              :yes
            end

          defp pub3(arg3) do
            :private
          end
        end
        """
      File.write("test/tmp/other_module.ex", content)

      {_ast, [f1, f2]} = Parser.public_functions("test/tmp/other_module.ex")

      assert f2.name == :pub1
      assert f2.start_line == 4
      assert f2.end_line == 6
      assert f1.name == :pub2
      assert f1.start_line == 8
    end

    test "it should return all versions of a public fn" do
      {_ast, [f1, f2]} =
        """
        defmodule ExFactorSampleModule do
          @somedoc "This is somedoc"
          # no aliases
          def pub1(arg1) do
            :ok
          end

          def pub1(:yes) do
            :yes
          end

          defp pub3(arg3) do
            :private
          end
        end
        """
        |> Code.string_to_quoted()
        |> Parser.public_functions()

      assert f2.name == :pub1
      assert f1.name == :pub1
    end

    test "ast references private fns and external fns called by a public fn" do
      content = """
      defmodule ExFactorOtherModule do
        def other_pub1(arg1), do: arg1
      end
      """

      File.write("test/tmp/other_module.ex", content)

      {_ast, fns} =
        """
        defmodule ExFactorSampleModule do
          def pub1(arg1) do
            inter = ExFactorOtherModule.other_pub1(arg1)
            priv2(inter)
          end

          defp priv2(arg2) do
            Map.get(args2, :key)
          end
        end
        """
        |> Code.string_to_quoted()
        |> Parser.public_functions()

      m = List.first(fns)
      Macro.decompose_call(m.ast)

      File.rm("test/tmp/other_module.ex")
    end
  end

  describe "private_functions/1" do
    test "it reports private fns for a filepath" do
      content = """
      defmodule ExFactorSampleModule do
        @somedoc "This is somedoc"
        # no aliases
        defp priv1(arg1) do
          :ok
        end

        def pub1(arg1) do
          :ok
        end
      end
      """

      File.mkdir_p("test/tmp")
      File.write("test/tmp/test_module.ex", content)
      {_ast, [f1]} = Parser.private_functions("test/tmp/test_module.ex")

      assert f1.name == :priv1
      assert f1.arity == 1
    end

    test "it should report private fns and arity" do
      {_ast, [f1]} =
        """
        defmodule ExFactorSampleModule do
          @somedoc "This is somedoc"
          defp priv1(arg1, arg2) do
            :ok
          end
        end
        """
        |> Code.string_to_quoted()
        |> Parser.private_functions()

      assert f1.name == :priv1
      assert f1.arity == 2
      assert f1.defn == :defp
    end

    test "it should report specs with start and end lines" do
      module = """
        defmodule ExFactorSampleModule do
          @spec priv1(term()) :: term()
          defp priv1(arg1) do
            :ok
          end
        end
        """

      File.write("test/tmp/other_module.ex", module)

      {_ast, [f1, f2]} = Parser.private_functions("test/tmp/other_module.ex")
      assert f1.name == :priv1
      assert f1.arity == 1
      assert f1.start_line == 3
      assert f1.end_line == 5

      assert f2.name == :priv1
      assert f2.defn == "@spec"
      assert f2.arity == 1
      assert f2.start_line == 2
      assert f2.end_line == 2
    end

    test "it should report specs with 0-arity" do
      module = """
        defmodule ExFactorSampleModule do
          @spec priv1() :: any()
          defp priv1() do
            :ok
          end
        end
        """

      File.write("test/tmp/other_module.ex", module)

      {_ast, [f1, f2]} = Parser.private_functions("test/tmp/other_module.ex")
      assert f1.name == :priv1
      assert f1.arity == 0
      assert f1.start_line == 3
      assert f1.end_line == 5

      assert f2.name == :priv1
      assert f2.defn == "@spec"
      assert f2.arity == 0
      assert f2.start_line == 2
      assert f2.end_line == 2
    end

    test "it should report TWO private fns" do
      {_ast, [f1, f2]} =
        """
        defmodule ExFactorSampleModule do
          @somedoc "This is somedoc"
          # no aliases
          def pub1(arg1) do
            :ok
          end

          def pub2(arg2) do
            :yes
          end

          defp priv3(arg3) do
            :private
          end

          defp priv4(arg4) do
            :private
          end
        end
        """
        |> Code.string_to_quoted()
        |> Parser.private_functions()

      assert f2.name == :priv3
      assert f1.name == :priv4
    end
  end

  describe "all_functions/1" do
    test "it should report all fns" do
      {_ast, [f1, f2, f3]} =
        """
        defmodule ExFactorSampleModule do
          @somedoc "This is somedoc"
          # no aliases
          def pub1(arg1) do
            :ok
          end

          def pub2(arg2) do
            :yes
          end

          defp priv3(arg3_1, arg3_2, arg3_3) do
            :private
          end
        end
        """
        |> Code.string_to_quoted()
        |> Parser.all_functions()

      assert f2.name == :pub1
      assert f1.name == :pub2
      assert f3.name == :priv3
      assert f3.defn == :defp
      assert f3.arity == 3
    end

    test "it should report all fns, don't dupe specs" do
      {_ast, functions} =
        """
        defmodule ExFactorSampleModule do
          @somedoc "This is somedoc"
          # no aliases
          @spec pub1(term()) :: term()
          def pub1(arg1) do
            :ok
          end

          @spec pub2(term()) :: term()
          def pub2(arg2) do
            :yes
          end

          @spec priv3(term(), term(), term()) :: term()
          defp priv3(arg3_1, arg3_2, arg3_3) do
            :private
          end
        end
        """
        |> Code.string_to_quoted()
        |> Parser.all_functions()

      assert Enum.count(functions, &(&1.defn == "@spec")) == 3
    end
  end

  describe "block_contents/1" do
    test "it returns the list with all the contents of the top-level block" do
      content = """
      defmodule ExFactorSampleModule do
        @somedoc "This is somedoc"
        # comments get dropped
        @doc "
        multiline
        documentation for pub1
        "
        def pub1(arg1) do
          :ok
        end
        _docp = "arbitrary module-level elem"
        defp priv1(arg1) do
          :ok
        end
      end
      """

      File.write("test/tmp/test_module.ex", content)
      {_ast, block} = Parser.block_contents("test/tmp/test_module.ex")

      assert [
               {:@, _, [{:somedoc, _, ["This is somedoc"]}]},
               {:@, _, [{:doc, _, ["\n  multiline\n  documentation for pub1\n  "]}]},
               {:def, _, [{:pub1, _, [{:arg1, _, nil}]}, _]},
               {:=, _, [{:_docp, _, nil}, "arbitrary module-level elem"]},
               {:defp, _, [{:priv1, _, [{:arg1, _, nil}]}, [do: :ok]]}
             ] = block
    end
  end

  describe "read_file/1" do
    test "it reads the file into an AST and list of each line" do
      content = """
      defmodule ExFactorSampleModule do
        @somedoc "This is somedoc"
        # comments get dropped
        _docp = "arbitrary module-level elem"
        def pub1(arg1) do
          :ok
        end
      end
      """

      File.write("test/tmp/test_module.ex", content)
      {ast, list} = Parser.read_file("test/tmp/test_module.ex")

      assert List.first(list) == "defmodule ExFactorSampleModule do"
      assert Enum.at(list, -2) == "end"
      assert {:defmodule, [do: [line: 1], end: [line: 8], line: 1], _} = ast
    end

    test "raises an exception for an invalid file path" do
      assert_raise File.Error, fn -> Parser.read_file("test/tmp/invalid.ex") end
    end
  end
end
