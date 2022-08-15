defmodule ExFactor.Support.ExampleTwo do
  @moduledoc """
  Support module for `ExFactor` testing.
  """

  # use alias as: to verify the caller is found.
  alias ExFactor.Parser, as: P

  def callers(mod), do: ExFactor.Callers.callers(mod)
  def all_functions(input), do: P.all_functions(input)

  defmodule SubModuleTwoA do
    @moduledoc false

    def example_func(arg_two) do
      IO.puts(inspect(arg_two, label: "arg_two"))
    end
  end
end
