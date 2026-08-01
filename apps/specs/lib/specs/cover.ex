defmodule Specs.Cover do
  import Enum, only: [each: 2, filter: 2, map: 2]
  import Path, only: [expand: 2, join: 2]

  @moduledoc """
  Start coverage instrumentation for dependencies.
  """

  def start do
    ready()
    paths() |> each(&load/1)
  end

  defp ready do
    :cover.start() |> ok?()
  end

  defp ok?({:ok, _}), do: :ok
  defp ok?({:error, {:already_started, _}}), do: :ok
  defp ok?(error), do: raise("cover.start: #{inspect(error)}")

  defp paths do
    root = expand("../../../..", __DIR__)
    ["el", "elita"] |> map(&ebin(root, &1))
  end

  defp ebin(root, name) do
    join(root, "_build/test/lib/#{name}/ebin")
  end

  defp load(dir) do
    dir |> to_charlist() |> compile(dir)
  end

  defp compile(charlist, dir) do
    :cover.compile_beam_directory(charlist) |> scan(dir)
  end

  defp scan(result, dir) when is_list(result) do
    result |> errs() |> check(dir)
  end

  defp scan(result, dir) do
    raise msg(dir, result)
  end

  defp check([], _), do: :ok
  defp check(errors, dir), do: raise(msg(dir, errors))

  defp errs(result) do
    filter(result, &match?({:error, _}, &1))
  end

  defp msg(dir, data) do
    "cover.compile_beam_directory: #{dir}: #{inspect(data)}"
  end
end
