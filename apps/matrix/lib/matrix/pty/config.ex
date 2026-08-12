defmodule Matrix.Pty.Config do
  @moduledoc false
  import Keyword, only: [get: 2, get: 3, drop: 2]
  import Matrix.Pty.Size, only: [default: 0]
  import Matrix.Movie.Record, only: [replaying?: 0]
  import Matrix.Movie.Load, only: [exists?: 1]

  def build(cmd, opts) do
    [file: file(opts), port: port(opts), cmd: cmd, name: get(opts, :name)] ++
      [get_size: size(opts), input: input(opts), taps: taps(opts)]
  end

  def finalize(opts, _cmd) do
    drop(opts, [:input, :taps, :cmd, :resize]) ++ defaults(opts)
  end

  defp defaults(opts) do
    [
      input: get(opts, :input, fn x -> x end),
      taps: get(opts, :taps, [])
    ]
  end

  defp file(opts), do: get(opts, :file, :file)
  defp port(opts), do: pick(opts[:port], opts)
  defp size(opts), do: get(opts, :get_size, &default/0)
  defp input(opts), do: get(opts, :input, fn x -> x end)
  defp taps(opts), do: get(opts, :taps, [])

  defp pick(nil, opts) do
    choose(replaying?(), exists?(opts[:name]))
  end

  defp pick(p, _opts), do: p

  defp choose(true, true), do: Matrix.Movie.Play
  defp choose(_, _), do: Port
end
