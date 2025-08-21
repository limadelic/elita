defmodule Utils.Reader do
  import File, only: [read: 1]

  def read_file(path) do
    case read(path) do
      {:ok, content} -> content
      {:error, _} -> "file not found: #{path}"
    end
  end
end