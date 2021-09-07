defmodule ExFactorTest do
  use ExUnit.Case
  alias ExFactor.Parser

  test "it should report public fns and their arity" do
    {_ast, [f1]} = """
    defmodule CredoSampleModule do
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
    {_ast, [f1, f2]} = """
    defmodule CredoSampleModule do
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

  test "it should report private fns and arity" do
    {_ast, [f1]} = """
    defmodule CredoSampleModule do
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
    {_ast, [f1, f2]} = """
    defmodule CredoSampleModule do
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

  test "it should report all fns" do
    {_ast, [f1, f2, f3]} = """
    defmodule CredoSampleModule do
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
