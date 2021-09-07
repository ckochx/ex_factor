defmodule ExFactorTest do
  use ExUnit.Case

  test "it should report public fns" do
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
    |> ExFactor.public_functions()

    assert f1.name == :pub1
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
    |> ExFactor.public_functions()
    assert f2.name == :pub1
    assert f1.name == :pub2
  end

  test "it should report private fns" do
    {_ast, [f1]} = """
    defmodule CredoSampleModule do
      @somedoc "This is somedoc"
      # no aliases
      defp priv1(arg1) do
        :ok
      end
    end
    """
    |> Code.string_to_quoted()
    |> ExFactor.private_functions()

    assert f1.name == :priv1
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
    |> ExFactor.private_functions()
    assert f2.name == :priv3
    assert f1.name == :priv4
  end
end
