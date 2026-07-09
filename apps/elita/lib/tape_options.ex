defmodule TapeOptions do
  def miss_opts("live"), do: [on_miss: :live]
  def miss_opts("swallow"), do: [on_miss: :swallow]
  def miss_opts(_), do: []
end
