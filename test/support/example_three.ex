defmodule ExFactor.Support.ExampleThree do
  @moduledoc """
  Support module for `ExFactor` testing.
  """

  # use alias as: to verify the caller is found.
  alias ExFactor.{Callers, Parser}
  # alias ExFactor.Callers

  def callers(mod), do: Callers.callers(mod)
  def all_functions(input), do: Parser.all_functions(input)
end


defmodule ExFactor.Support.ExampleFour do
  defmodule SubModuleTwoA do
    @moduledoc false

    def example_func(arg_two) do
      IO.puts(inspect(arg_two, label: "arg_two"))
    end
  end
end