defmodule ExFactor.Formatter do
  @moduledoc """
  `ExFactor.Formatter` Format a list of files
  """

  def format(args, opts \\ [])

  def format([nil], _opts), do: nil

  def format(paths, opts) do
    if Keyword.get(opts, :format, true) do
      Enum.map(paths, fn path ->
        path
        |> Code.format_file!()
        |> then(fn contents ->
          File.write!(path, contents, [:write])
        end)
      end)
    end
  end
end
