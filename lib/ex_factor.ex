defmodule ExFactor do
  @moduledoc """
  `ExFactor` is a refactoring helper.

  By identifying a Module, function name, and arity, it will identify all non-test usages
  and extract them to a new Module.

  If the Module exists, it add the function to the end of the file and change all calls to the
  new module's name.
  """
end
