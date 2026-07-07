defmodule El.Commands.Address do
  import Agent.Config, only: [load: 0]
  import El.Commands.Lookup, only: [local: 2]

  def route(recipient, msg) do
    world = world()
    cwd = cwd()
    result = Resolver.resolve(recipient, world, cwd)
    handle(result, recipient, msg)
  end

  defp handle({:error, :unknown}, recipient, _msg), do: IO.puts("unknown: #{recipient}")
  defp handle({:ok, entry}, _recipient, msg), do: local(entry.name, msg)
  defp handle({:many, _}, _recipient, _msg), do: IO.puts("ask requires one target")

  defp world do
    load()
    |> Enum.map(fn {name, folder} ->
      %{name: Atom.to_string(name), path: Path.expand(folder), kind: :folder}
    end)
  end

  defp cwd do
    File.cwd!() |> strip_private()
  end

  defp strip_private("/private" <> rest), do: rest
  defp strip_private(path), do: path
end
