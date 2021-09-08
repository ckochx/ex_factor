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

    test "it should report TWO public fns" do
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

          defp pub3(arg3) do
            :private
          end
        end
        """
        |> Code.string_to_quoted()
        |> Parser.public_functions()

      assert f2.name == :pub1
      assert f1.name == :pub2
    end

    test "ast references private fns and external fns called by a public fn" do
      content = """
      defmodule ExFactorOtherModule do
        def other_pub1(arg1), do: arg1
      end
      """
      File.write("test/support/other_module.ex", content)

      {ast, fns} = """
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
      |> IO.inspect(label: "")

      m = List.first(fns)
      Macro.decompose_call(m.ast)
      |> IO.inspect(label: "decompose_call")
      # assert f2.name == :pub1
      # assert f1.name == :pub2
      File.rm("test/support/other_module.ex")
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
  end
end
