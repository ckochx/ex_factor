defmodule ExFactor.Formatter do
  @moduledoc """
  Documentation for `ExFactor.Formatter`.
  Format a list of files
  """

  def format(args) do
    Mix.Tasks.Format.run(args)
  end
end
