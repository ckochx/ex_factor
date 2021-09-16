defmodule ExFactorSampleModule do
  @somedoc "This is somedoc"
  # comments get dropped
  @doc "
  multiline
  documentation for pub1
  "
# @spec: pub1/1 removed by ExFactor

# @spec: pub1/1 removed by ExFactor

#
# Function: pub1/1 removed by ExFactor
# ExFactor only removes the function itself
# Other artifacts, including docs and module-level comments
# may remain for you to remove manually.
#

  defp priv1(arg1) do
    :ok
  end

  def pub2(arg1)
    do
      :ok
    end

end
