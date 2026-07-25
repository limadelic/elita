defmodule Matrix.Pty.Log do
  @moduledoc false
  import IO, only: [binwrite: 2]

  def dump(nil, _), do: :ok
  def dump(fd, data), do: binwrite(fd, data)
end
