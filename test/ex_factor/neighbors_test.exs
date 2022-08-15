defmodule ExFactor.NeighborsTest do
  use ExUnit.Case
  alias ExFactor.Neighbors
  alias ExFactor.Parser

  describe "prev/1" do
    test "it should report neighbors (which aren't functions) before the target fn" do
      module =
        """
        defmodule ExFactorSampleModule do
          use Some.Other.Library
          import Some.Third.Lib
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
        |> Code.string_to_quoted()

      {_ast, block} = Parser.block_contents(module)

      assert [
               {:@, _, [{:somedoc, _, ["This is somedoc"]}]},
               {:@, _, [{:doc, _, ["\n  multiline\n  documentation for pub1\n  "]}]},
               {:def, _, [{:pub1, _, [{:arg1, _, nil}]}, _]}
             ] = Neighbors.walk(block, :pub1)
    end

    test "it should handle the first function without anything before" do
      module =
        """
        defmodule ExFactorSampleModule do
          def pub1(arg1) do
            :ok
          end
          _docp = "arbitrary module-level elem"
          defp priv1(arg1) do
            :ok
          end
        end
        """
        |> Code.string_to_quoted()

      {_ast, block} = Parser.block_contents(module)

      assert [
               {:def, _, [{:pub1, _, [{:arg1, _, nil}]}, _]}
             ] = Neighbors.walk(block, :pub1)
    end

    test "it should handle the first function without anything else" do
      module =
        """
        defmodule ExFactorSampleModule do
          def pub1(arg1) do
            :ok
          end
        end
        """
        |> Code.string_to_quoted()

      {_ast, block} = Parser.block_contents(module)

      assert [
               {:def, _, [{:pub1, _, [{:arg1, _, nil}]}, _]}
             ] = Neighbors.walk(block, :pub1)
    end

    test "it finds the target when the last function and function is a string" do
      module =
        """
        defmodule ExFactorSampleModule do
          def pub1(arg1) do
            :ok
          end
          _docp = "arbitrary module-level elem"
          defp priv1(arg1) do
            :ok
          end
          def pub2(arg2) do
            :ok
          end
        end
        """
        |> Code.string_to_quoted()

      {_ast, block} = Parser.block_contents(module)

      assert [
               {:def, _, [{:pub2, _, [{:arg2, _, nil}]}, _]}
             ] = Neighbors.walk(block, "pub2")
    end

    test "it should ignore the aliases" do
      module =
        """
        defmodule ExFactorSampleModule do
          alias ExFactor.OtherModule
          def pub1(arg1) do
            :ok
          end
          _docp = "arbitrary module-level elem"
          defp priv1(arg1) do
            :ok
          end
        end
        """
        |> Code.string_to_quoted()

      {_ast, block} = Parser.block_contents(module)

      assert [
               {:def, _, [{:pub1, _, [{:arg1, _, nil}]}, _]}
             ] = Neighbors.walk(block, :pub1)
    end

    test "it should ignore the use, import, and require" do
      module =
        """
        defmodule ExFactorSampleModule do
          alias ExFactor.OtherModule
          use OtherModule
          import OtherModule
          require OtherModule
          def pub1(arg1) do
            :ok
          end
          _docp = "arbitrary module-level elem"
          defp priv1(arg1) do
            :ok
          end
        end
        """
        |> Code.string_to_quoted()

      {_ast, block} = Parser.block_contents(module)

      assert [
               {:def, _, [{:pub1, _, [{:arg1, _, nil}]}, _]}
             ] = Neighbors.walk(block, :pub1)
    end
    test "it should ignore types" do
      module =
        """
        defmodule ExFactorSampleModule do
          @type word :: String.t()
          @module_attr ~w(one, two, three)a
          def pub1(arg1) do
            :ok
          end
          _docp = "arbitrary module-level elem"
          defp priv1(arg1) do
            :ok
          end
        end
        """
        |> Code.string_to_quoted()

      {_ast, block} = Parser.block_contents(module)

      assert [
               {:def, _, [{:pub1, _, [{:arg1, _, nil}]}, _]}
             ] = Neighbors.walk(block, :pub1)
    end

    test "it should return all the instances of a target fn" do
      module =
        """
        defmodule ExFactorSampleModule do
          def pub1(:error) do
            :error
          end
          def pub1(:ok), do: ok
          def pub1(arg1) do
            :ok
          end
        end
        """
        |> Code.string_to_quoted()

      {_ast, block} = Parser.block_contents(module)

      assert [
               {:def, [line: 2], [{:pub1, [line: 2], [:error]}, [do: :error]]},
               {:def, [line: 5], [{:pub1, [line: 5], [:ok]}, [do: {:ok, [line: 5], nil}]]},
               {:def, [line: 6], [{:pub1, [line: 6], [{:arg1, [line: 6], nil}]}, [do: :ok]]}
             ] = Neighbors.walk(block, :pub1)
    end

    test "it should return all the instances of a target fn with optional arity match" do
      module =
        """
        defmodule ExFactorSampleModule do
          def pub1(:error) do
            :error
          end
          def pub1(:ok), do: ok
          def pub1(arg1, arg2) do
            :ok
          end
        end
        """
        |> Code.string_to_quoted()

      {_ast, block} = Parser.block_contents(module)

      assert [
               {:def, [line: 2], [{:pub1, [line: 2], [:error]}, [do: :error]]},
               {:def, [line: 5], [{:pub1, [line: 5], [:ok]}, [do: {:ok, [line: 5], nil}]]}
             ] = Neighbors.walk(block, :pub1, 1)
    end

    test "it should return all the instances of a target fn, specs, docs, and arbitrary" do
      module =
        """
        defmodule ExFactorSampleModule do
          @doc "doc pub1-1"
          def pub1(:error) do
            :error
          end
          @spec pub1(term()) :: term()
          def pub1(:ok), do: ok
          _docp = "docp pub1-1"
          def pub1(arg1) do
            :ok
          end
        end
        """
        |> Code.string_to_quoted()

      {_ast, block} = Parser.block_contents(module)

      assert [
               {:@, [line: 2], [{:doc, [line: 2], ["doc pub1-1"]}]},
               {:def, [line: 3], [{:pub1, [line: 3], [:error]}, [do: :error]]},
               {:@, [line: 6],
                [
                  {:spec, [line: 6],
                   [
                     {:"::", [line: 6],
                      [{:pub1, [line: 6], [{:term, [line: 6], []}]}, {:term, [line: 6], []}]}
                   ]}
                ]},
               {:def, [line: 7], [{:pub1, [line: 7], [:ok]}, [do: {:ok, [line: 7], nil}]]},
               {:=, [line: 8], [{:_docp, [line: 8], nil}, "docp pub1-1"]},
               {:def, [line: 9], [{:pub1, [line: 9], [{:arg1, [line: 9], nil}]}, [do: :ok]]}
             ] = Neighbors.walk(block, :pub1)
    end
  end
end
