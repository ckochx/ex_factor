defmodule ExFactor.RemoverTest do
  use ExUnit.Case
  alias ExFactor.Remover
  # alias ExFactor.Parser

  setup_all do
    File.mkdir_p("test/tmp")

    # on_exit(fn ->
    #   File.rm_rf("test/tmp")
    # end)
  end

  describe "remove/1" do
    test "it rewrites the source file and removes code blocks" do
      module =
        """
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
        # |> Code.string_to_quoted()

      File.write("test/tmp/source_module.ex", module)

      # {_ast, [f1, f2]} = Parser.public_functions("test/tmp/source_module.ex")
      # {_ast, [f1, f2]} = Parser.public_functions("test/tmp/source_module.ex")

      # {_ast, block} = Parser.block_contents("test/tmp/source_module.ex")
      Remover.remove("test/tmp/source_module.ex", :pub1, 1)

      # assert [
      #          {:@, _, [{:somedoc, _, ["This is somedoc"]}]},
      #          {:@, _, [{:doc, _, ["\n  multiline\n  documentation for pub1\n  "]}]},
      #          {:def, _, [{:pub1, _, [{:arg1, _, nil}]}, _]}
      #        ] = Remover.walk(block, :pub1)
      updated_file = File.read!("test/tmp/source_module.ex")
      refute updated_file =~ "def pub1(arg1) do"
      assert updated_file =~ "Function: pub1/1 removed by ExFactor"
      # it removes specs too
      refute updated_file =~ "@spec pub1(term()) :: term()"
    end

    # test "it removes specs too" do
    # end
  end
end
