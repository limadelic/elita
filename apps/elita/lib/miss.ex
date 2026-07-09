defmodule Miss do
  def opts("live"), do: [on_miss: :live]
  def opts("swallow"), do: [on_miss: :swallow]
  def opts(_), do: []
end
