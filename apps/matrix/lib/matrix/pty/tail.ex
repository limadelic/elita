defmodule Matrix.Pty.Tail do
  @moduledoc false
  import String, only: [slice: 2]

  def grow(nil, d), do: cap(d)
  def grow(tail, d), do: cap(tail <> d)

  defp cap(t) when byte_size(t) > 4096, do: slice(t, -4096..-1)
  defp cap(t), do: t
end
