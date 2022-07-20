defmodule ExFactor.Formatter do
  @moduledoc """
  `ExFactor.Formatter` Format a list of files
  """

  def format([nil]), do: nil

  def format(args) do
    Mix.Tasks.Format.run(args)
  end
end
