defmodule El.Commands.Cd do
  import El.Commands.Address.World, only: [cwd: 0]
  import El.Standpoint, only: [set: 1, birth: 0]
  import Resolver, only: [normalize: 2]

  def execute(path) do
    here = cwd()
    absolute = resolve(path, here)
    :ok = verify(absolute)
    set(absolute)
  end

  defp resolve("~", _here), do: birth()
  defp resolve(path, here), do: normalize(path, here)

  defp verify(path) do
    guard(File.dir?(path))
  end

  defp guard(true), do: :ok
  defp guard(false), do: :error
end
