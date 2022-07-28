defmodule ExFactor.Formatter do
  @moduledoc """
  `ExFactor.Formatter` Format a list of files
  """

  def format(args, opts \\ [])

  def format([nil], _opts), do: nil

  def format(args, opts) do
    if Keyword.get(opts, :format, true) do
      Mix.Tasks.Format.run(args)
    end
  end
end
