defmodule Sweep do
  import Path, only: [join: 2]
  import System, only: [get_env: 2, os_time: 1]
  import File, only: [ls: 1, rm: 1, stat: 1]
  import Enum, only: [each: 2]

  def sweep do
    with {:ok, names} <- ls(dir()) do
      each(names, &purge(&1, os_time(:second) - 604_800))
    end
  end

  defp purge(name, cutoff) do
    with {:ok, s} <- stat(join(dir(), name)), true <- s.mtime < cutoff do
      rm(join(dir(), name))
    end
  end

  defp dir do
    join(get_env("HOME", "~"), ".elita/sessions")
  end
end
